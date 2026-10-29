# Implementation Plan: AI Agent Tool Access

## 1. Kết quả cần đạt

Mỗi AI Agent có identity riêng, lấy JWT từ Keycloak và chỉ thấy/gọi được các MCP tool được cấp qua capability role. Tool write/execute phải bị tách khỏi tool read; backend đích vẫn áp dụng resource-level authorization; tất cả allow/deny đều có audit evidence.

Tài liệu thiết kế: [ai-agent-tool-access.md](ai-agent-tool-access.md).

## 2. Phạm vi MVP

MVP sử dụng 5 mock backend và 21 tool hiện có. Triển khai trước các role:

```text
kube_viewer
kube_operator
spark_viewer
metadata_viewer
metadata_editor
dbt_viewer
dbt_operator
airflow_viewer
airflow_operator
platform_admin
```

MVP xác thực agent tự trị bằng OAuth client credentials. Delegation khi agent hành động thay người dùng chưa nằm trong MVP.

## 3. Các phase triển khai

### Phase 0 — Đồng bộ baseline

- Xác nhận agentgateway/Gateway API version thực tế.
- Chạy lại `servers/smoke_test.py` và `tests/gateway_smoke.py`.
- Chốt catalog 21 tool làm baseline trong `tests/expected/`.
- Sửa tài liệu cũ còn mô tả ba backend thay vì năm backend.

**Exit criteria:** catalog và toàn bộ 21 mock call pass; expected data được commit.

### Phase 1 — Keycloak agent identities

- Tạo realm/client configuration có thể tái lập trong `deploy/keycloak/`.
- Tạo audience/resource client `mcp-gateway`.
- Tạo các capability role của MVP.
- Tạo confidential client/service account riêng cho từng agent.
- Gán role tối thiểu theo bảng thiết kế.
- Thêm mapper để token có `aud=mcp-gateway`, agent client identity và claim `roles`.
- Lưu secret ngoài Git; ưu tiên secret manager hoặc Kubernetes Secret được provision từ bên ngoài.

**Tests:**

- Client hợp lệ lấy được token bằng `client_credentials`.
- Token có đúng issuer, audience, agent identity và roles.
- Client không có role không tự yêu cầu được role cao hơn.
- Secret/token không xuất hiện trong log hoặc evidence.

**Exit criteria:** mỗi agent có token phân biệt được và đúng role.

### Phase 2 — Gateway JWT authentication

- Tạo manifest authentication trong `deploy/auth/`.
- Bật strict JWT validation trên Gateway.
- Kiểm tra signature/JWKS, issuer, audience và expiry.
- Chỉ tạo identity headers từ verified claims và ghi đè header client gửi vào.
- Xác nhận exact CRD fields với agentgateway version đang cài; không sao chép nguyên sketch trong guideline nếu chưa kiểm chứng.

**Tests:**

- Không token, token hết hạn, sai issuer và sai audience đều bị từ chối.
- Token đúng được qua authentication.
- Forged identity header không thay đổi identity backend nhìn thấy.

**Exit criteria:** chỉ token hợp lệ dành cho `mcp-gateway` đến được MCP authorization layer.

### Phase 3 — Tool RBAC

- Tạo `rbac/tool-access.yaml` làm source of truth.
- Viết allow rules theo `roles + mcp.tool.target + mcp.tool.name`.
- Tách read và write/execute theo thiết kế.
- Thêm target condition nếu cần ẩn hoàn toàn target không được phép.
- Chỉ cấp `platform_admin` qua quy trình break-glass.

**Tests:**

- `tools/list` của mỗi agent chỉ chứa catalog được cấp.
- Gọi tool được cấp thành công.
- Gọi trực tiếp một tool bị ẩn vẫn bị deny.
- Multi-role agent nhận union chính xác.
- Agent không role thấy/gọi được zero tool.

**Exit criteria:** role × tool matrix pass cho cả discovery và invocation.

### Phase 4 — Expected matrix và automation

- Tạo machine-readable matrix tại `tests/expected/`, ưu tiên YAML hoặc JSON.
- Mỗi record gồm agent, roles, expected visible tools và denied tools.
- Viết script lấy token cho service account mà không in token ra stdout.
- Mở rộng integration test để chạy toàn bộ agent matrix.
- Mọi thay đổi RBAC bắt buộc cập nhật expected matrix trong cùng PR.

**Exit criteria:** một lệnh test kiểm chứng toàn bộ allow/deny matrix và trả exit code khác 0 khi lệch policy.

### Phase 5 — Resource-level enforcement

- Với Radar thật, ánh xạ identity/role đã xác thực sang Kubernetes user/group hoặc workload identity phù hợp.
- Tạo Kubernetes Role/RoleBinding theo namespace; tránh ClusterRoleBinding nếu không cần.
- Giới hạn `manage_workload` theo action, namespace và resource kind.
- Giới hạn Airflow operator theo DAG/environment.
- Giới hạn OpenMetadata editor theo domain/entity.
- Giới hạn dbt operator theo environment và selector.

**Tests:**

- Gateway cho phép tool nhưng backend từ chối resource ngoài phạm vi.
- Agent không đọc/sửa được namespace hoặc entity ngoài quyền.
- Không agent thông thường nào sửa được Secret, RBAC hoặc system namespace.

**Exit criteria:** vượt qua gateway không đồng nghĩa với quyền không giới hạn ở backend.

### Phase 6 — Network boundary và audit

- Triển khai NetworkPolicy để backend chỉ nhận ingress từ gateway.
- Xác nhận CNI của kind thực thi NetworkPolicy.
- Tạo access-log policy ghi agent identity, roles, target, tool, decision và correlation/request ID.
- Log backend không chứa bearer token hoặc client secret.
- Đặt rate limit/timeout cho agent và tool có side effect.

**Tests:**

- Pod ngoài gateway không kết nối trực tiếp tới backend.
- Allow và deny đều có audit record đúng agent/tool.
- Có thể truy vết một tool call xuyên gateway và backend bằng correlation ID.

**Exit criteria:** identity headers đáng tin cậy và mọi quyết định quan trọng audit được.

### Phase 7 — Real backend rollout

- Thay từng mock bằng backend thật, không đổi target/tool contract nếu có thể.
- Bật read-only agent trước.
- Với write/execute tool, thêm approval gate hoặc policy phù hợp mức rủi ro.
- Canary theo agent identity; chuẩn bị revoke client và rollback route/policy.
- Đối chiếu quyền thực tế của backend với expected matrix.

**Exit criteria:** backend thật giữ nguyên deny-by-default, least privilege và auditability của MVP.

## 4. Ma trận identity và role khởi điểm

| Agent client | Roles |
|---|---|
| `cluster-observer-agent` | `kube_viewer` |
| `incident-response-agent` | `kube_operator`, `spark_viewer` |
| `spark-diagnostic-agent` | `spark_viewer` |
| `metadata-discovery-agent` | `metadata_viewer` |
| `metadata-steward-agent` | `metadata_editor` |
| `dbt-quality-agent` | `dbt_operator` |
| `airflow-monitor-agent` | `airflow_viewer` |
| `airflow-operator-agent` | `airflow_operator` |
| `platform-admin-agent` | `platform_admin` |

Các role operator/editor bao gồm quyền viewer tương ứng bằng composite role hoặc bằng nhiều rule rõ ràng. Chọn một cách và test effective token claims, không dựa vào giả định về role inheritance.

## 5. Definition of Done

- [ ] Mỗi agent có confidential client/service account riêng.
- [ ] JWT được validate đầy đủ và đúng audience.
- [ ] Có source-of-truth role × target × tool.
- [ ] `tools/list` và `tools/call` đều enforce policy.
- [ ] Read và write/execute được tách role.
- [ ] Expected matrix chạy tự động cho mọi agent.
- [ ] Backend/resource RBAC chặn truy cập ngoài phạm vi.
- [ ] Backend chỉ nhận traffic từ gateway.
- [ ] Allow/deny có audit record nhưng không lộ secret/token.
- [ ] Có quy trình rotate/revoke agent credential.
- [ ] `platform_admin` chỉ dùng break-glass.
- [ ] Tài liệu và evidence phản ánh cấu hình đã chạy thực tế.

## 6. Ngoài phạm vi MVP

- User delegation/On-Behalf-Of và giao quyền tương tác.
- Multi-agent delegation hoặc agent gọi agent.
- Dynamic Client Registration mở cho agent không được quản lý.
- Fine-grained approval workflow cho từng tool call.
- Production secret manager, HSM hoặc certificate-bound tokens.

Các mục này chỉ được triển khai sau khi identity, tool RBAC, backend RBAC và audit của agent tự trị đã ổn định.

## 7. Trạng thái thực thi

Đã triển khai trong repository:

- Keycloak realm import với 10 confidential service-account clients (9 agent chức năng và 1 negative-test agent), secret lấy từ Kubernetes Secret.
- JWT validation, audience check và verified identity-header transformation.
- Deny-by-default role × target × tool policy cho 21 tool.
- Machine-readable expected matrix và integration test cho token claims, discovery, allow và deny.
- Kubernetes RBAC mẫu theo namespace, NetworkPolicy và agent-aware access log policy.
- Secret bootstrap và deployment orchestration scripts.
- Static contract test bảo đảm catalog, realm clients/roles và expected matrix không lệch nhau.

Đã kiểm chứng trong môi trường phát triển hiện tại:

- `node tests/static_contract_test.mjs`: pass với 21 tools và 10 agent identities.
- `bash -n scripts/*.sh`: pass.
- Python sources compile thành công.
- `uv run --with 'mcp==1.30.0' python servers/smoke_test.py`: cả 5 mock backend list/call tool thành công.

Môi trường local hiện đã có Docker Desktop, `kubectl`, kind, Helm và cluster `kind-mcp` Kubernetes 1.37 với Calico. Bằng chứng nằm tại `evidence/environment-setup.txt`.

Đã kiểm chứng end-to-end trên cluster mới:

- Keycloak realm import và client-credentials claims của 10 identities.
- Ba AgentgatewayPolicy đều `Accepted=True` và `Attached=True` trên agentgateway v1.5.0.
- Agent × Tool discovery/allow/deny matrix pass toàn bộ.
- Backend nhận đúng `x-agent-id` và `x-forwarded-user` từ verified JWT.
- NetworkPolicy chặn namespace ngoài gateway và cho phép `agentgateway-system`.
- Audit logs có agent, role, method, target, tool và kết quả allow/deny.

Chưa triển khai: backend thật, OpenMetadata token exchange, user delegation và production secret/audit storage.
