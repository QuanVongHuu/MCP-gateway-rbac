# AI Agent Tool Access

## 1. Mục tiêu

Thiết kế cơ chế phân quyền để mỗi AI Agent chỉ nhìn thấy và gọi được các MCP tool cần cho nhiệm vụ của mình. Agent được nhận diện bằng JWT riêng; agentgateway kiểm soát quyền ở mức target/tool; backend và Kubernetes tiếp tục giới hạn tài nguyên thực tế.

Mô hình thống nhất:

```text
AI Agent identity -> capability roles -> MCP targets/tools -> backend resource permissions
```

- **Agent identity**: danh tính máy riêng cho từng agent, không dùng chung token của developer.
- **Capability role**: tập quyền ổn định như `kube_viewer` hoặc `airflow_operator`.
- **Tool policy**: ánh xạ role tới MCP target và tool.
- **Resource policy**: giới hạn namespace, workload, DAG hoặc metadata entity tại backend đích.

## 2. Nguyên tắc

1. Deny-by-default: không có rule phù hợp thì không được thấy hoặc gọi tool.
2. Least privilege: agent chỉ nhận role cần cho nhiệm vụ.
3. Tách quyền read và write/execute.
4. Không tin identity header do client gửi; gateway phải tạo hoặc ghi đè header sau khi xác thực JWT.
5. Tool filtering không thay thế authorization khi gọi tool.
6. Gateway RBAC không thay thế Kubernetes RBAC hoặc quyền của hệ thống backend.
7. Mỗi lời gọi cần audit được `agent_id`, role, target, tool, kết quả và user ủy quyền nếu có.
8. `platform_admin` chỉ dùng cho break-glass, không gán cho agent chạy thường xuyên.

## 3. Các Agent của MVP

| Agent | Nhiệm vụ | Capability role |
|---|---|---|
| `cluster-observer-agent` | Quan sát namespace, resource và pod log | `kube_viewer` |
| `incident-response-agent` | Điều tra Spark và thực hiện remediation có giới hạn | `kube_operator`, `spark_viewer` |
| `spark-diagnostic-agent` | Phân tích application, stage và bottleneck | `spark_viewer` |
| `metadata-discovery-agent` | Tìm kiếm metadata, chi tiết entity và lineage | `metadata_viewer` |
| `metadata-steward-agent` | Cập nhật metadata đã được cho phép | `metadata_editor` |
| `dbt-quality-agent` | Kiểm tra metric, model, lineage và chạy dbt test | `dbt_operator` |
| `airflow-monitor-agent` | Theo dõi DAG, DAG run và task log | `airflow_viewer` |
| `airflow-operator-agent` | Theo dõi, trigger và pause DAG được cho phép | `airflow_operator` |
| `platform-admin-agent` | Break-glass trên toàn bộ tool | `platform_admin` |

`platform-admin-agent` không thuộc luồng vận hành bình thường và phải có quy trình cấp token, TTL và audit riêng.

## 4. Capability roles và tool hiện có

Repository hiện cấu hình 5 MCP target với 21 tool. Các tool write/execute của mock không tạo side effect, nhưng phải được xem là tool nguy hiểm vì backend thật sẽ có side effect.

### Kubernetes/Radar

| Role | Tools |
|---|---|
| `kube_viewer` | `radar_list_namespaces`, `radar_list_resources`, `radar_get_pod_logs` |
| `kube_operator` | Toàn bộ `kube_viewer` và `radar_manage_workload` |

Với `radar_manage_workload`, backend/Kubernetes phải giới hạn thêm `action`, namespace, resource kind và resource name. Không cho phép agent tự thay đổi RBAC, Secret hoặc workload hệ thống.

### Spark History

| Role | Tools |
|---|---|
| `spark_viewer` | `spark-history_list_applications`, `spark-history_get_stage`, `spark-history_get_job_bottlenecks` |

Ba tool hiện tại đều là read-only.

### OpenMetadata

| Role | Tools |
|---|---|
| `metadata_viewer` | `openmetadata_search_metadata`, `openmetadata_get_entity_details`, `openmetadata_get_entity_lineage` |
| `metadata_editor` | Toàn bộ `metadata_viewer` và `openmetadata_patch_entity` |

Backend thật phải tiếp tục kiểm tra domain, owner và entity mà agent được sửa.

### dbt

| Role | Tools |
|---|---|
| `dbt_viewer` | `dbt_list_metrics`, `dbt_query_metrics`, `dbt_get_model_health`, `dbt_get_lineage` |
| `dbt_operator` | Toàn bộ `dbt_viewer` và `dbt_test` |

`dbt_test` được xem là execute vì có thể tạo workload và tiêu thụ tài nguyên trên môi trường thật.

### Airflow

| Role | Tools |
|---|---|
| `airflow_viewer` | `airflow_list_dags`, `airflow_get_dag_run`, `airflow_get_task_logs` |
| `airflow_operator` | Toàn bộ `airflow_viewer`, `airflow_trigger_dag`, `airflow_pause_dag` |

Backend thật phải giới hạn danh sách DAG, environment và hành động mà agent được phép thực hiện.

### Break-glass

| Role | Tools |
|---|---|
| `platform_admin` | Toàn bộ target/tool hiện tại và tool được thêm sau này |

## 5. Authentication và authorization flow

```text
1. Agent dùng OAuth client credentials để lấy access token từ Keycloak.
2. Token có audience `mcp-gateway`, identity của agent và các capability role.
3. Agent gọi endpoint `/mcp` với Bearer token.
4. agentgateway xác thực signature, issuer, audience và thời hạn token.
5. agentgateway dùng JWT claims + MCP target/tool để lọc `tools/list` và kiểm tra `tools/call`.
6. Gateway chuyển identity đã xác thực tới backend theo cơ chế phù hợp.
7. Backend/Kubernetes kiểm tra quyền tài nguyên trước khi thực thi.
8. Gateway và backend ghi audit log.
```

Mỗi agent nên là một Keycloak confidential client/service account riêng. Không dùng một client chung cho nhiều agent vì sẽ không phân biệt được actor khi audit hoặc revoke.

JWT tối thiểu cần có:

| Claim | Ý nghĩa |
|---|---|
| `iss` | Keycloak realm phát hành token |
| `aud` | Phải chứa `mcp-gateway` |
| `sub` | Subject ổn định của service account |
| `azp` hoặc `client_id` | Client đại diện cho agent |
| `roles` | Capability roles của agent |

Nếu agent hành động thay người dùng, cần giữ cả `agent_id` và `user_id`; quyền hiệu lực không được vượt quá quyền đã được user ủy quyền. Luồng này tách khỏi MVP agent tự trị và cần thiết kế token exchange/delegation riêng.

## 6. Ví dụ policy logic

Policy cần kiểm tra cả identity/role và target/tool, ví dụ về mặt logic:

```text
role == kube_viewer
AND target == radar
AND tool IN [list_namespaces, list_resources, get_pod_logs]
```

```text
role == kube_operator
AND target == radar
AND tool == manage_workload
```

Không chỉ dựa vào tên agent do request body hoặc header cung cấp. Identity phải đến từ JWT đã được gateway xác thực.

## 7. Trạng thái hiện tại

- Đã có 5 mock target và catalog 21 tool.
- Đã có smoke test gọi toàn bộ tool qua gateway.
- Chưa có Keycloak service account cho AI Agent.
- Chưa có JWT authentication policy và tool RBAC operational.
- Chưa có expected matrix theo agent/role.
- Chưa có NetworkPolicy và audit policy operational.
- Mock write tools hiện không tạo thay đổi thật.

Kế hoạch hiện thực hóa thiết kế nằm tại [idea.md](idea.md).
