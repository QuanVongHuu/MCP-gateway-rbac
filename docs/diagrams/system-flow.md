# MCP Gateway RBAC — Mô tả flow hệ thống

Sơ đồ đi kèm: [system-architecture.drawio](system-architecture.drawio). Các số (1)–(7) trong tài liệu khớp với nhãn trên mũi tên của sơ đồ.

## Tổng quan

MCP Gateway RBAC đặt **agentgateway v1.5.0** trước nhiều MCP server trong một cluster Kubernetes (kind `gatewayapi`). Người dùng hoặc AI agent chỉ nói chuyện với **một endpoint duy nhất** `http://localhost:8080/mcp`. Gateway lần lượt xác thực token Keycloak, lọc/chặn tool theo role, gắn danh tính người gọi rồi định tuyến tới đúng backend. Dự án không viết code gateway: toàn bộ là cấu hình YAML (Gateway API + `AgentgatewayPolicy`), mock backend và test.

Năm thành phần chính:

| Thành phần | Namespace / nơi chạy | Vai trò |
|---|---|---|
| MCP client (Inspector, AI agent) + `scripts/get-token.sh` | máy local, qua `kubectl port-forward` | lấy token, gọi `tools/list`, `tools/call` |
| Keycloak 26.2, realm `mcp` | `keycloak` | cấp JWT (`aud=mcp-gateway`, claim `roles`), JWKS, token exchange |
| agentgateway-proxy | `agentgateway-system` | JWT auth → tool RBAC → identity → route → access log |
| MCP backends (`AgentgatewayBackend mcp-backend`) | `mcp` (+ Docker trên network `kind`) | radar, spark-history, openmetadata, dbt, airflow |
| Observability | `observability` | Alloy → Loki → Grafana dashboard allow/deny |

## Flow một lần gọi tool

**(1) Lấy token.** `scripts/get-token.sh <user>` gọi `/realms/mcp/protocol/openid-connect/token` (password grant, client `mcp-gateway`). Keycloak trả access token có `iss=http://localhost:8002/realms/mcp`, `aud=mcp-gateway` và claim `roles` lấy từ client role của `mcp-gateway` (gán trực tiếp hoặc qua group `data-team` → `data_engineer`, `bi-team` → `bi_engineer`).

**(2) Gọi gateway.** Client gửi `POST /mcp` (Streamable HTTP) kèm `Authorization: Bearer <token>` tới `localhost:8080`, port-forward vào service `agentgateway-proxy:80`. `HTTPRoute mcp` khớp prefix `/mcp` và trỏ tới `AgentgatewayBackend mcp-backend`.

**(3) Xác thực (deploy/auth/jwt.yaml).** Policy `jwt` gắn vào Gateway ở chế độ `Strict`: thiếu token hoặc token sai chữ ký/issuer/audience bị từ chối ngay. Khoá công khai lấy từ JWKS endpoint của Keycloak, cache 5 phút.

**(4) Phân quyền tool (rbac/tool-access.yaml).** Policy `tool-access` gắn vào backend, gồm các biểu thức CEL trên `jwt.roles`, `mcp.tool.target`, `mcp.tool.name`. Các rule được OR với nhau nên user nhiều role nhận hợp quyền; không rule nào khớp nghĩa là không có quyền. Rule áp dụng ở cả hai điểm: `tools/list` chỉ trả về tool được phép, và `tools/call` một tool bị cấm (kể cả khi đoán đúng tên) bị chặn với HTTP 400 `Unknown tool`. Ví dụ: `analyst` chỉ đọc metadata OpenMetadata; `bi_engineer` thêm `patch_entity`; `data_engineer` đọc radar, toàn bộ spark-history, đọc dbt/airflow; `data_admin` được tất cả.

**(5) Gắn danh tính và định tuyến.** Transformation ở Gateway đặt `x-forwarded-user = jwt.preferred_username`, `x-forwarded-groups = roles` và xoá header `Authorization`; token gốc chỉ được giữ tạm trong `x-caller-token` rồi bị policy `strip-caller-token` xoá trước khi tới backend. Backend multiplex 5 target với `prefixMode: Always`, nên tool hiện ra dạng `{target}_{tool}` (ví dụ `radar_list_namespaces`).

**(6) Token exchange (chỉ OpenMetadata).** Với target `openmetadata`, policy `openmetadata-token-exchange` đổi `x-caller-token` lấy token mới `aud=openmetadata` tại endpoint `/token` của Keycloak (standard token exchange, client secret `mcp-gateway-client-secret`). OpenMetadata tự áp quyền của chính nó theo user đó.

**(7) Audit.** Policy `access-logs` thêm `user`, `roles`, `mcp_method`, `mcp_target`, `mcp_tool` vào mỗi dòng log của proxy. Alloy thu stdout của pod `agentgateway-proxy`, đẩy vào Loki; Grafana (`localhost:3000`) dựng dashboard *MCP Gateway – Allow and Deny* (200 = allow, 400 `Unknown tool` = deny).

## Backend và cách nhận danh tính

| Target | Server | Chạy ở | Nhận danh tính người gọi |
|---|---|---|---|
| `radar` | skyhook-io/radar 1.16.0 (Helm `radar-real`) | kind, ns `mcp` | header identity; radar impersonate user, Kubernetes RBAC quyết định |
| `openmetadata` | OpenMetadata 1.13.3 | Docker, network `kind` | token đã exchange (`aud=openmetadata`) |
| `spark-history` | Spark History Server MCP 1.0.1 | Docker, network `kind` | không nhận được danh tính |
| `dbt`, `airflow` | mock (`mcp-mocks:dev`) | kind, ns `mcp` | header identity |

`NetworkPolicy backends-from-gateway-only` chỉ cho phép ingress vào ns `mcp` từ ns `agentgateway-system`, nên header identity là đáng tin. Hai server chạy Docker nằm ngoài NetworkPolicy này (giới hạn đã ghi trong `deploy/real-servers/README.md`). Gateway khởi tạo mọi target khi mở session, nên một target chết sẽ làm `initialize` lỗi cho tất cả người gọi.

## Chuỗi checkpoint

| Checkpoint | Câu hỏi | Nơi cấu hình |
|---|---|---|
| Network | Pod này có tới được backend không? | `deploy/network/` |
| Authentication | Token có thật và đúng audience? | `deploy/keycloak/`, `deploy/auth/` |
| Authorization | Role này có được gọi tool này? | `rbac/tool-access.yaml` |
| Identity | Backend biết gì về người gọi? | `deploy/auth/` (header), `deploy/identity/` (token exchange) |
| Audit | Ai đã làm gì, được hay bị chặn? | `observability/access-logs/`, `observability/grafana/` |

Nguồn: `README.md`, `deploy/**`, `rbac/tool-access.yaml`, `observability/**`, `deploy/real-servers/README.md` trong repo MCP-gateway-rbac.
