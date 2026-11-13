<div align="center">

# MCP Gateway RBAC

**One authenticated, role-filtered MCP endpoint for every AI agent and every tool.**

<p>
  <a href="https://agentgateway.dev"><img src="https://img.shields.io/badge/agentgateway-v1.5.0-7B3FE4?style=for-the-badge&labelColor=1F2328&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB3aWR0aD0iMzE1IiBoZWlnaHQ9IjMxNSIgdmlld0JveD0iMjUwIDI1MCA1NjUgNTY1IiBmaWxsPSJub25lIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik01MzIuODYgMzkwLjgzMUM1NzEuNjg0IDM5MC44MzEgNjAzLjE1NyAzNTkuNDgxIDYwMy4xNTcgMzIwLjgwOUM2MDMuMTU3IDI4Mi4xMzYgNTcxLjY4NCAyNTAuNzg2IDUzMi44NiAyNTAuNzg2QzQ5NC4wMzYgMjUwLjc4NiA0NjIuNTYyIDI4Mi4xMzYgNDYyLjU2MiAzMjAuODA5QzQ2Mi41NjIgMzU5LjQ4MSA0OTQuMDM2IDM5MC44MzEgNTMyLjg2IDM5MC44MzFaIiBmaWxsPSIjNzczNGJlIi8%2BPHBhdGggZD0iTTUzMi44NiA2MDIuMjY4QzU3MS42ODQgNjAyLjI2OCA2MDMuMTU3IDU3MC45MTggNjAzLjE1NyA1MzIuMjQ2QzYwMy4xNTcgNDkzLjU3MyA1NzEuNjg0IDQ2Mi4yMjMgNTMyLjg2IDQ2Mi4yMjNDNDk0LjAzNiA0NjIuMjIzIDQ2Mi41NjIgNDkzLjU3MyA0NjIuNTYyIDUzMi4yNDZDNDYyLjU2MiA1NzAuOTE4IDQ5NC4wMzYgNjAyLjI2OCA1MzIuODYgNjAyLjI2OFoiIGZpbGw9IiM3NzM0YmUiLz48cGF0aCBkPSJNNTczLjEwOSA0MjYuNDMxQzU3My4xMDkgNDAxLjE5OSA1ODAuMzc0IDM3Ny41MzIgNTkyLjc0NSAzNTcuMzg2TDUzMi44NTUgMzIwLjYxNEw0NzIuOTY1IDM1Ny4zODZDNDg1LjMzNiAzNzcuNTMyIDQ5Mi42MDEgNDAxLjAwMyA0OTIuNjAxIDQyNi40MzFDNDkyLjYwMSA0NTEuODU4IDQ4NS4zMzYgNDc1LjMyOSA0NzIuOTY1IDQ5NS40NzVMNTMyLjg1NSA1MzIuMjQ3TDU5Mi43NDUgNDk1LjQ3NUM1ODAuMzc0IDQ3NS4zMjkgNTczLjEwOSA0NTEuODU4IDU3My4xMDkgNDI2LjQzMVoiIGZpbGw9IiM3NzM0YmUiLz48cGF0aCBkPSJNNzA1LjQ1MyA0OTYuNDUyQzc0NC4yNzcgNDk2LjQ1MiA3NzUuNzUgNDY1LjEwMSA3NzUuNzUgNDI2LjQyOUM3NzUuNzUgMzg3Ljc1NiA3NDQuMjc3IDM1Ni40MDYgNzA1LjQ1MyAzNTYuNDA2QzY2Ni42MjkgMzU2LjQwNiA2MzUuMTU2IDM4Ny43NTYgNjM1LjE1NiA0MjYuNDI5QzYzNS4xNTYgNDY1LjEwMSA2NjYuNjI5IDQ5Ni40NTIgNzA1LjQ1MyA0OTYuNDUyWiIgZmlsbD0iIzc3MzRiZSIvPjxwYXRoIGQ9Ik03MDUuNDUzIDcwNy44ODlDNzQ0LjI3NyA3MDcuODg5IDc3NS43NSA2NzYuNTM4IDc3NS43NSA2MzcuODY2Qzc3NS43NSA1OTkuMTk0IDc0NC4yNzcgNTY3Ljg0MyA3MDUuNDUzIDU2Ny44NDNDNjY2LjYyOSA1NjcuODQzIDYzNS4xNTYgNTk5LjE5NCA2MzUuMTU2IDYzNy44NjZDNjM1LjE1NiA2NzYuNTM4IDY2Ni42MjkgNzA3Ljg4OSA3MDUuNDUzIDcwNy44ODlaIiBmaWxsPSIjNzczNGJlIi8%2BPHBhdGggZD0iTTc0NS43MDMgNTMyLjI0NkM3NDUuNzAzIDUwNy4wMTQgNzUyLjk2OCA0ODMuMzQ4IDc2NS4zMzkgNDYzLjIwMUw3MDUuNDQ5IDQyNi40M0w2NDUuNTU5IDQ2My4yMDFDNjU3LjkyOSA0ODMuMzQ4IDY2NS4xOTUgNTA2LjgxOSA2NjUuMTk1IDUzMi4yNDZDNjY1LjE5NSA1NTcuNjczIDY1Ny45MjkgNTgxLjE0NSA2NDUuNTU5IDYwMS4yOTFMNzA1LjQ0OSA2MzguMDYyTDc2NS4zMzkgNjAxLjI5MUM3NTIuOTY4IDU4MS4xNDUgNzQ1LjcwMyA1NTcuNjczIDc0NS43MDMgNTMyLjI0NloiIGZpbGw9IiM3NzM0YmUiLz48cGF0aCBkPSJNMzYwLjA1OSA0OTYuNDUyQzM5OC44ODMgNDk2LjQ1MiA0MzAuMzU2IDQ2NS4xMDEgNDMwLjM1NiA0MjYuNDI5QzQzMC4zNTYgMzg3Ljc1NiAzOTguODgzIDM1Ni40MDYgMzYwLjA1OSAzNTYuNDA2QzMyMS4yMzUgMzU2LjQwNiAyODkuNzYyIDM4Ny43NTYgMjg5Ljc2MiA0MjYuNDI5QzI4OS43NjIgNDY1LjEwMSAzMjEuMjM1IDQ5Ni40NTIgMzYwLjA1OSA0OTYuNDUyWiIgZmlsbD0iIzc3MzRiZSIvPjxwYXRoIGQ9Ik0zNjAuMDU5IDcwNy44ODdDMzk4Ljg4MyA3MDcuODg3IDQzMC4zNTYgNjc2LjUzNyA0MzAuMzU2IDYzNy44NjVDNDMwLjM1NiA1OTkuMTkyIDM5OC44ODMgNTY3Ljg0MiAzNjAuMDU5IDU2Ny44NDJDMzIxLjIzNSA1NjcuODQyIDI4OS43NjIgNTk5LjE5MiAyODkuNzYyIDYzNy44NjVDMjg5Ljc2MiA2NzYuNTM3IDMyMS4yMzUgNzA3Ljg4NyAzNjAuMDU5IDcwNy44ODdaIiBmaWxsPSIjNzczNGJlIi8%2BPHBhdGggZD0iTTQwMC4zMDggNTMyLjI0NUM0MDAuMzA4IDUwNy4wMTMgNDA3LjU3MyA0ODMuMzQ2IDQxOS45NDQgNDYzLjJMMzYwLjA1NCA0MjYuNDI4TDMwMC4xNjQgNDYzLjJDMzEyLjUzNSA0ODMuMzQ2IDMxOS44IDUwNi44MTcgMzE5LjggNTMyLjI0NUMzMTkuOCA1NTcuNjcyIDMxMi41MzUgNTgxLjE0MyAzMDAuMTY0IDYwMS4yODlMMzYwLjA1NCA2MzguMDYxTDQxOS45NDQgNjAxLjI4OUM0MDcuNTczIDU4MS4xNDMgNDAwLjMwOCA1NTcuNjcyIDQwMC4zMDggNTMyLjI0NVoiIGZpbGw9IiM3NzM0YmUiLz48cGF0aCBkPSJNNTMyLjg2IDgxMy41MTFDNTcxLjY4NCA4MTMuNTExIDYwMy4xNTcgNzgyLjE2IDYwMy4xNTcgNzQzLjQ4OEM2MDMuMTU3IDcwNC44MTYgNTcxLjY4NCA2NzMuNDY1IDUzMi44NiA2NzMuNDY1QzQ5NC4wMzYgNjczLjQ2NSA0NjIuNTYyIDcwNC44MTYgNDYyLjU2MiA3NDMuNDg4QzQ2Mi41NjIgNzgyLjE2IDQ5NC4wMzYgODEzLjUxMSA1MzIuODYgODEzLjUxMVoiIGZpbGw9IiM3NzM0YmUiLz48L3N2Zz4%3D" alt="agentgateway"></a>
  <a href="https://modelcontextprotocol.io"><img src="https://img.shields.io/badge/MCP-Streamable_HTTP-3B3B3B?style=for-the-badge&labelColor=1F2328&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyBmaWxsPSIjZmZmZmZmIiByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dGl0bGU%2BTW9kZWwgQ29udGV4dCBQcm90b2NvbDwvdGl0bGU%2BPHBhdGggZD0iTTEzLjg1IDBhNC4xNiA0LjE2IDAgMCAwLTIuOTUgMS4yMTdMMS40NTYgMTAuNjZhLjgzNS44MzUgMCAwIDAgMCAxLjE4LjgzNS44MzUgMCAwIDAgMS4xOCAwbDkuNDQyLTkuNDQyYTIuNDkgMi40OSAwIDAgMSAzLjU0MSAwIDIuNDkgMi40OSAwIDAgMSAwIDMuNTQxTDguNTkgMTIuOTdsLS4xLjFhLjgzNS44MzUgMCAwIDAgMCAxLjE4LjgzNS44MzUgMCAwIDAgMS4xOCAwbC4xLS4wOTggNy4wMy03LjAzNGEyLjQ5IDIuNDkgMCAwIDEgMy41NDIgMGwuMDQ5LjA1YTIuNDkgMi40OSAwIDAgMSAwIDMuNTRsLTguNTQgOC41NGExLjk2IDEuOTYgMCAwIDAgMCAyLjc1NWwxLjc1MyAxLjc1M2EuODM1LjgzNSAwIDAgMCAxLjE4IDAgLjgzNS44MzUgMCAwIDAgMC0xLjE4bC0xLjc1My0xLjc1M2EuMjY2LjI2NiAwIDAgMSAwLS4zOTRsOC41NC04LjU0YTQuMTg1IDQuMTg1IDAgMCAwIDAtNS45bC0uMDUtLjA1YTQuMTYgNC4xNiAwIDAgMC0yLjk1LTEuMjE4Yy0uMiAwLS40MDEuMDItLjYuMDQ4YTQuMTcgNC4xNyAwIDAgMC0xLjE3LTMuNTUyQTQuMTYgNC4xNiAwIDAgMCAxMy44NSAwbTAgMy4zMzNhLjg0Ljg0IDAgMCAwLS41OS4yNDVMNi4yNzUgMTAuNTZhNC4xODYgNC4xODYgMCAwIDAgMCA1LjkwMiA0LjE4NiA0LjE4NiAwIDAgMCA1LjkwMiAwTDE5LjE2IDkuNDhhLjgzNS44MzUgMCAwIDAgMC0xLjE4LjgzNS44MzUgMCAwIDAtMS4xOCAwbC02Ljk4NSA2Ljk4NGEyLjQ5IDIuNDkgMCAwIDEtMy41NCAwIDIuNDkgMi40OSAwIDAgMSAwLTMuNTRsNi45ODMtNi45ODVhLjgzNS44MzUgMCAwIDAgMC0xLjE4Ljg0Ljg0IDAgMCAwLS41OS0uMjQ1Ii8%2BPC9zdmc%2B" alt="MCP"></a>
  <a href="https://www.keycloak.org"><img src="https://img.shields.io/badge/Keycloak-26.2-008AAA?style=for-the-badge&labelColor=1F2328&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyBmaWxsPSIjMzNDNkY0IiByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dGl0bGU%2BS2V5Y2xvYWs8L3RpdGxlPjxwYXRoIGQ9Im0xOC43NDIgMS4xODItMTIuNDkzLjAwMkM0LjE1NSA0Ljc4NCAyLjA3OSA4LjM5MyAwIDEyLjAwMmMyLjA3MSAzLjYxMiA0LjE2MiA3LjIxNCA2LjI1MiAxMC44MTZsMTIuNDktLjAwNCAzLjA4OS01LjQwNGgyLjE1OHYtLjAwMkgyNEwyMy45OTYgNi41OWgtMi4xNjh6TTguMzI3IDQuNzkyaDIuMDgxbDEuMDQgMS44LTMuMTIgNS40MTMgMy4xMTcgNS40MDMtMS4wMzUgMS44MUg4LjMyN2EyMDQ3LjU2NiAyMDQ3LjU2NiAwIDAgMC00LjE2OC03LjIwNEM1LjU0NyA5LjYwNiA2LjkzNyA3LjIgOC4zMjcgNC43OTJabTYuMjQxIDAgMi4wODYuMDAzYzEuMzkzIDIuNDA1IDIuNzggNC44MTMgNC4xNjYgNy4yMjJsLTQuMTY3IDcuMmgtMi4wOGMtLjM4Mi0uNTYyLTEuMDM4LTEuODA4LTEuMDM4LTEuODA4bDMuMTIzLTUuNDA1LTMuMTI0LTUuNDEzeiIvPjwvc3ZnPg%3D%3D" alt="Keycloak"></a>
  <img src="https://img.shields.io/badge/OAuth_2.0-JWT-D63AFF?style=for-the-badge&labelColor=1F2328&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyBmaWxsPSIjZmZmZmZmIiByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dGl0bGU%2BSlNPTiBXZWIgVG9rZW5zPC90aXRsZT48cGF0aCBkPSJNMTAuMiAwdjYuNDU2TDEyIDguOTI4bDEuOC0yLjQ3MlYwem0zLjYgNi40NTZ2My4wNzJsMi45MDQtLjk2TDIwLjUyIDMuMzZsLTIuOTI4LTIuMTM2em0yLjkwNCAyLjExMmwtMS44IDIuNDk2IDIuOTI4LjkzNiA2LjE0NC0xLjk5Mi0xLjEyOC0zLjQzMnpNMTcuODMyIDEybC0yLjkyOC45MzYgMS44IDIuNDk2IDYuMTQ0IDEuOTkyIDEuMTI4LTMuNDMyem0tMS4xMjggMy40MzJsLTIuOTA0LS45NnYzLjA3MmwzLjc5MiA1LjIzMiAyLjkyOC0yLjEzNnpNMTMuOCAxNy41NDRMMTIgMTUuMDcybC0xLjggMi40NzJWMjRoMy42em0tMy42IDB2LTMuMDcybC0yLjkwNC45NkwzLjQ4IDIwLjY0bDIuOTI4IDIuMTM2em0tMi45MDQtMi4xMTJsMS44LTIuNDk2TDYuMTY4IDEyIC4wMjQgMTMuOTkybDEuMTI4IDMuNDMyek02LjE2OCAxMmwyLjkyOC0uOTM2LTEuOC0yLjQ5Ni02LjE0NC0xLjk5Mi0xLjEyOCAzLjQzMnptMS4xMjgtMy40MzJsMi45MDQuOTZWNi40NTZMNi40MDggMS4yMjQgMy40OCAzLjM2WiIvPjwvc3ZnPg%3D%3D" alt="OAuth 2.0">
</p>
<p>
  <a href="https://kind.sigs.k8s.io"><img src="https://img.shields.io/badge/Kubernetes-kind-326CE5?style=for-the-badge&labelColor=1F2328&logo=kubernetes&logoColor=326CE5" alt="Kubernetes"></a>
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&labelColor=1F2328&logo=docker&logoColor=2496ED" alt="Docker">
  <img src="https://img.shields.io/badge/Helm-charts-0F1689?style=for-the-badge&labelColor=1F2328&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyBmaWxsPSIjZmZmZmZmIiByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dGl0bGU%2BSGVsbTwvdGl0bGU%2BPHBhdGggZD0iTTEyLjMzNyAwYy0uNDc1IDAtLjg2MSAxLjAxNi0uODYxIDIuMjY5IDAgLjUyNy4wNjkgMS4wMTEuMTgzIDEuMzk2YTguNTE0IDguNTE0IDAgMCAwLTMuOTYxIDEuMjIgNS4yMjkgNS4yMjkgMCAwIDAtLjU5NS0xLjA5M2MtLjYwNi0uODY2LTEuMzQtMS40MzYtMS43OS0xLjQzYS4zODEuMzgxIDAgMCAwLS4yMTcuMDY2Yy0uMzkuMjczLS4xMjMgMS4zMjYuNTk2IDIuMzUzLjI2Ny4zODEuNTU5LjcwNS44NC45NDhhOC42ODMgOC42ODMgMCAwIDAtMS41MjggMS43MTZoMS43MzRhNy4xNzkgNy4xNzkgMCAwIDEgNS4zODEtMi40MjEgNy4xOCA3LjE4IDAgMCAxIDUuMzgyIDIuNDJoMS43MzNhOC42ODcgOC42ODcgMCAwIDAtMS4zMi0xLjUzYy4zNS0uMjQ5LjczNS0uNjQzIDEuMDc4LTEuMTMzLjcxOS0xLjAyNy45ODYtMi4wOC41OTYtMi4zNTNhLjM4Mi4zODIgMCAwIDAtLjIxNy0uMDY1Yy0uNDUtLjAwNy0xLjE4NC41NjMtMS43OSAxLjQzYTQuODk3IDQuODk3IDAgMCAwLS42NzYgMS4zMjUgOC41MiA4LjUyIDAgMCAwLTMuODk5LTEuNDJjLjEyLS4zOS4xOTMtLjg4Ny4xOTMtMS40MjkgMC0xLjI1My0uMzg2LTIuMjY5LS44NjItMi4yNjl6TTEuNjI0IDkuNDQzdjUuMTYyaDEuMzU4di0xLjk2OGgxLjY0djEuOTY4aDEuMzU3VjkuNDQzSDQuNjJ2MS44MzhIMi45OFY5LjQ0M3ptNS45MTIgMHY1LjE2MmgzLjIxdi0xLjEwOEg4Ljg5M3YtLjk1aDEuNjR2LTEuMTQyaC0xLjY0di0uODRoMS44NTNWOS40NDN6bTQuNjk4IDB2NS4xNjJoMy4yMTh2LTEuMzYyaC0xLjg2di0zLjh6bTQuNzA2IDB2NS4xNjJoMS4zNjR2LTIuNjQzbDEuMzU3IDEuMjI1IDEuMzUtMS4yMzJ2Mi42NWgxLjM2NVY5LjQ0M2gtLjYxNGwtMi4xIDEuOTE0LTIuMTA5LTEuOTE0em0tMTEuODIgNy4yOGE4LjY4OCA4LjY4OCAwIDAgMCAxLjQxMiAxLjU0OCA1LjIwNiA1LjIwNiAwIDAgMC0uODQxLjk0OGMtLjcxOSAxLjAyNy0uOTg1IDIuMDgtLjU5NiAyLjM1My4zOS4yNzMgMS4yODktLjMzOCAyLjAwNy0xLjM2NGE1LjIzIDUuMjMgMCAwIDAgLjU5NS0xLjA5MiA4LjUxNCA4LjUxNCAwIDAgMCAzLjk2MSAxLjIxOSA1LjAxIDUuMDEgMCAwIDAtLjE4MyAxLjM5NmMwIDEuMjUzLjM4NiAyLjI2OS44NjEgMi4yNjkuNDc2IDAgLjg2Mi0xLjAxNi44NjItMi4yNjkgMC0uNTQyLS4wNzItMS4wNC0uMTkzLTEuNDNhOC41MiA4LjUyIDAgMCAwIDMuOS0xLjQyYy4xMjEuNC4zNTIuODY1LjY3NSAxLjMyNy43MTkgMS4wMjYgMS42MTcgMS42MzcgMi4wMDcgMS4zNjQuMzktLjI3My4xMjMtMS4zMjYtLjU5Ni0yLjM1My0uMzQzLS40OS0uNzI3LS44ODUtMS4wNzctMS4xMzVhOC42OSA4LjY5IDAgMCAwIDEuMjAyLTEuMzZoLTEuNzcxYTcuMTc0IDcuMTc0IDAgMCAxLTUuMjI3IDIuMjUyIDcuMTc0IDcuMTc0IDAgMCAxLTUuMjI2LTIuMjUyeiIvPjwvc3ZnPg%3D%3D" alt="Helm">
  <img src="https://img.shields.io/badge/Grafana-Loki_%C2%B7_Alloy-F46800?style=for-the-badge&labelColor=1F2328&logo=grafana&logoColor=F46800" alt="Grafana">
</p>
<p>
  <img src="https://img.shields.io/badge/Python-FastMCP-3776AB?style=for-the-badge&labelColor=1F2328&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMjggMTI4Ij48bGluZWFyR3JhZGllbnQgaWQ9InB5dGhvbi1vcmlnaW5hbC1hIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIgeDE9IjcwLjI1MiIgeTE9IjEyMzcuNDc2IiB4Mj0iMTcwLjY1OSIgeTI9IjExNTEuMDg5IiBncmFkaWVudFRyYW5zZm9ybT0ibWF0cml4KC41NjMgMCAwIC0uNTY4IC0yOS4yMTUgNzA3LjgxNykiPjxzdG9wIG9mZnNldD0iMCIgc3RvcC1jb2xvcj0iIzVBOUZENCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzMwNjk5OCIvPjwvbGluZWFyR3JhZGllbnQ%2BPGxpbmVhckdyYWRpZW50IGlkPSJweXRob24tb3JpZ2luYWwtYiIgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiIHgxPSIyMDkuNDc0IiB5MT0iMTA5OC44MTEiIHgyPSIxNzMuNjIiIHkyPSIxMTQ5LjUzNyIgZ3JhZGllbnRUcmFuc2Zvcm09Im1hdHJpeCguNTYzIDAgMCAtLjU2OCAtMjkuMjE1IDcwNy44MTcpIj48c3RvcCBvZmZzZXQ9IjAiIHN0b3AtY29sb3I9IiNGRkQ0M0IiLz48c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiNGRkU4NzMiLz48L2xpbmVhckdyYWRpZW50PjxwYXRoIGZpbGw9InVybCgjcHl0aG9uLW9yaWdpbmFsLWEpIiBkPSJNNjMuMzkxIDEuOTg4Yy00LjIyMi4wMi04LjI1Mi4zNzktMTEuOCAxLjAwNy0xMC40NSAxLjg0Ni0xMi4zNDYgNS43MS0xMi4zNDYgMTIuODM3djkuNDExaDI0LjY5M3YzLjEzN0gyOS45NzdjLTcuMTc2IDAtMTMuNDYgNC4zMTMtMTUuNDI2IDEyLjUyMS0yLjI2OCA5LjQwNS0yLjM2OCAxNS4yNzUgMCAyNS4wOTYgMS43NTUgNy4zMTEgNS45NDcgMTIuNTE5IDEzLjEyNCAxMi41MTloOC40OTFWNjcuMjM0YzAtOC4xNTEgNy4wNTEtMTUuMzQgMTUuNDI2LTE1LjM0aDI0LjY2NWM2Ljg2NiAwIDEyLjM0Ni01LjY1NCAxMi4zNDYtMTIuNTQ4VjE1LjgzM2MwLTYuNjkzLTUuNjQ2LTExLjcyLTEyLjM0Ni0xMi44MzctNC4yNDQtLjcwNi04LjY0NS0xLjAyNy0xMi44NjYtMS4wMDh6TTUwLjAzNyA5LjU1N2MyLjU1IDAgNC42MzQgMi4xMTcgNC42MzQgNC43MjEgMCAyLjU5My0yLjA4MyA0LjY5LTQuNjM0IDQuNjktMi41NiAwLTQuNjMzLTIuMDk3LTQuNjMzLTQuNjktLjAwMS0yLjYwNCAyLjA3My00LjcyMSA0LjYzMy00LjcyMXoiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDAgMTAuMjYpIi8%2BPHBhdGggZmlsbD0idXJsKCNweXRob24tb3JpZ2luYWwtYikiIGQ9Ik05MS42ODIgMjguMzh2MTAuOTY2YzAgOC41LTcuMjA4IDE1LjY1NS0xNS40MjYgMTUuNjU1SDUxLjU5MWMtNi43NTYgMC0xMi4zNDYgNS43ODMtMTIuMzQ2IDEyLjU0OXYyMy41MTVjMCA2LjY5MSA1LjgxOCAxMC42MjggMTIuMzQ2IDEyLjU0NyA3LjgxNiAyLjI5NyAxNS4zMTIgMi43MTMgMjQuNjY1IDAgNi4yMTYtMS44MDEgMTIuMzQ2LTUuNDIzIDEyLjM0Ni0xMi41NDd2LTkuNDEySDYzLjkzOHYtMy4xMzhoMzcuMDEyYzcuMTc2IDAgOS44NTItNS4wMDUgMTIuMzQ4LTEyLjUxOSAyLjU3OC03LjczNSAyLjQ2Ny0xNS4xNzQgMC0yNS4wOTYtMS43NzQtNy4xNDUtNS4xNjEtMTIuNTIxLTEyLjM0OC0xMi41MjFoLTkuMjY4ek03Ny44MDkgODcuOTI3YzIuNTYxIDAgNC42MzQgMi4wOTcgNC42MzQgNC42OTIgMCAyLjYwMi0yLjA3NCA0LjcxOS00LjYzNCA0LjcxOS0yLjU1IDAtNC42MzMtMi4xMTctNC42MzMtNC43MTkgMC0yLjU5NSAyLjA4My00LjY5MiA0LjYzMy00LjY5MnoiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDAgMTAuMjYpIi8%2BPHJhZGlhbEdyYWRpZW50IGlkPSJweXRob24tb3JpZ2luYWwtYyIgY3g9IjE4MjUuNjc4IiBjeT0iNDQ0LjQ1IiByPSIyNi43NDMiIGdyYWRpZW50VHJhbnNmb3JtPSJtYXRyaXgoMCAtLjI0IC0xLjA1NSAwIDUzMi45NzkgNTU3LjU3NikiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj48c3RvcCBvZmZzZXQ9IjAiIHN0b3AtY29sb3I9IiNCOEI4QjgiIHN0b3Atb3BhY2l0eT0iLjQ5OCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzdGN0Y3RiIgc3RvcC1vcGFjaXR5PSIwIi8%2BPC9yYWRpYWxHcmFkaWVudD48cGF0aCBvcGFjaXR5PSIuNDQ0IiBmaWxsPSJ1cmwoI3B5dGhvbi1vcmlnaW5hbC1jKSIgZD0iTTk3LjMwOSAxMTkuNTk3YzAgMy41NDMtMTQuODE2IDYuNDE2LTMzLjA5MSA2LjQxNi0xOC4yNzYgMC0zMy4wOTItMi44NzMtMzMuMDkyLTYuNDE2IDAtMy41NDQgMTQuODE1LTYuNDE3IDMzLjA5Mi02LjQxNyAxOC4yNzUgMCAzMy4wOTEgMi44NzIgMzMuMDkxIDYuNDE3eiIvPjwvc3ZnPg%3D%3D" alt="Python">
  <img src="https://img.shields.io/badge/Apache_Airflow-mock-017CEE?style=for-the-badge&labelColor=1F2328&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB2aWV3Qm94PSIwIDAgMTI4IDEyOCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJtMi41NDQxIDEyNyA2MC44MDktNjIuMzMyYTEuMTI0IDEuMTI0IDAgMCAwIDAuMTM1OS0xLjQzNjhjLTMuNjk3Ny01LjE2MjUtMTAuNTIxLTYuMDU3OC0xMy4wNS05LjUyNjgtNy40OTAzLTEwLjI3NS05LjM5MDktMTYuMDkyLTEyLjYxLTE1LjczMWEwLjk4Mzc0IDAuOTgzNzQgMCAwIDAtMC41ODQ2NCAwLjMwODVsLTIxLjk2NiAyMi41MThjLTEyLjYzOCAxMi45NDQtMTQuNDU0IDQxLjQ3NS0xNC43ODIgNjUuMzY3YTEuMTkwOCAxLjE5MDggMCAwIDAgMi4wNDczIDAuODMyNzN6IiBmaWxsPSIjMDE3Y2VlIi8%2BPHBhdGggZD0ibTEyNi45OSAxMjUuNDYtNjIuMzMyLTYwLjgxM2ExLjEyNCAxLjEyNCAwIDAgMC0xLjQzODktMC4xMzU5Yy01LjE2MjUgMy42OTk4LTYuMDU3OCAxMC41MjEtOS41MjY4IDEzLjA1LTEwLjI3NSA3LjQ5MDMtMTYuMDkyIDkuMzkwOS0xNS43MzEgMTIuNjFhMC45ODM3NCAwLjk4Mzc0IDAgMCAwIDAuMzA4NSAwLjU4MjQ4bDIyLjUxOCAyMS45NjZjMTIuOTQ0IDEyLjYzOCA0MS40NzUgMTQuNDU0IDY1LjM2NyAxNC43ODJhMS4xOTA4IDEuMTkwOCAwIDAgMCAwLjgzNDg5LTIuMDQwOHoiIGZpbGw9IiMwMGFkNDYiLz48cGF0aCBkPSJtNjAuNzkyIDExMi43MmMtNy4wNzYtNi45MDM1LTEwLjM1NS0yMC41NTkgMy4yMDU4LTQ4LjcxOS0yMi4wNDYgOS44NTI1LTI5Ljc3MSAyMi44MDMtMjUuOTcyIDI2LjUxMXoiIGZpbGw9IiMwNGQ2NTkiLz48cGF0aCBkPSJtMTI1LjQ1IDEuMDExMy02MC44MDcgNjIuMzMyYTEuMTIxOCAxLjEyMTggMCAwIDAtMC4xMzU5IDEuNDM2OGMzLjY5OTggNS4xNjI1IDEwLjUxOSA2LjA1NzggMTMuMDUgOS41MjY4IDcuNDkwMyAxMC4yNzUgOS4zOTMgMTYuMDkyIDEyLjYxIDE1LjczMWEwLjk3OTQzIDAuOTc5NDMgMCAwIDAgMC41ODQ2NC0wLjMwODVsMjEuOTY2LTIyLjUxOGMxMi42MzgtMTIuOTQ0IDE0LjQ1NC00MS40NzUgMTQuNzgyLTY1LjM2N2ExLjE5MyAxLjE5MyAwIDAgMC0yLjA0OTUtMC44MzI3M3oiIGZpbGw9IiMwMGM3ZDQiLz48cGF0aCBkPSJtMTEyLjczIDY3LjIxMWMtNi45MDM1IDcuMDc2LTIwLjU1OSAxMC4zNTUtNDguNzIxLTMuMjA1OCA5Ljg1MjUgMjIuMDQ2IDIyLjgwMyAyOS43NzEgMjYuNTExIDI1Ljk3MnoiIGZpbGw9IiMxMWUxZWUiLz48cGF0aCBkPSJtMS4wMDE3IDIuNTQ5NSA2Mi4zMzIgNjAuODA3YTEuMTI0IDEuMTI0IDAgMCAwIDEuNDM2OCAwLjEzNTljNS4xNjI1LTMuNjk5OCA2LjA1NzgtMTAuNTIxIDkuNTI2OC0xMy4wNSAxMC4yNzUtNy40OTAzIDE2LjA5Mi05LjM5MDkgMTUuNzMxLTEyLjYxYTAuOTkwMjIgMC45OTAyMiAwIDAgMC0wLjMwODUtMC41ODQ2M2wtMjIuNTE4LTIxLjk2NmMtMTIuOTQ0LTEyLjYzOC00MS40NzUtMTQuNDU0LTY1LjM2Ny0xNC43ODJhMS4xOTA4IDEuMTkwOCAwIDAgMC0wLjgzMjczIDIuMDQ5NXoiIGZpbGw9IiNlNDM5MjEiLz48cGF0aCBkPSJtNjcuMjEyIDE1LjI4NGM3LjA3NiA2LjkwMzUgMTAuMzU1IDIwLjU1OS0zLjIwNTggNDguNzIxIDIyLjA0Ni05Ljg1MjUgMjkuNzcxLTIyLjgwNSAyNS45NzItMjYuNTExeiIgZmlsbD0iI2ZmNzU1NyIvPjxwYXRoIGQ9Im0xNS4yNzkgNjAuOGM2LjkwMzUtNy4wNzYgMjAuNTU5LTEwLjM1NSA0OC43MjEgMy4yMDU4LTkuODUyNS0yMi4wNDYtMjIuODAzLTI5Ljc3MS0yNi41MTEtMjUuOTcyeiIgZmlsbD0iIzBjYjZmZiIvPjxjaXJjbGUgY3g9IjY0LjAwOSIgY3k9IjYzLjk5NSIgcj0iMi43MTgyIiBmaWxsPSIjNGE0ODQ4Ii8%2BPC9zdmc%2B" alt="Apache Airflow">
  <img src="https://img.shields.io/badge/Apache_Spark-History-E25A1C?style=for-the-badge&labelColor=1F2328&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMjggMTI4Ij48cGF0aCBmaWxsPSIjZTE1OTE5IiBkPSJNNTcuNjQ2LjAwNGMtMi4yNjkuMDY0LTQuNTEgMS4xNDMtNi4zODQgMy4yMjMtMS4wMyAxLjE0Ni0xLjkwNSAyLjUxLTIuNjMgMy44NTUtMS44OSAzLjU0LTIuMjYyIDcuNTQ3LTIuOTYyIDExLjQzbC0zLjg1MiAyMS44MWMtLjE0OC44NTYtLjUzMiAxLjIxLTEuMyAxLjQ1NWwtMjguMjY4IDguOThjLTIuMDYuNjczLTQuMTI1IDEuNTQzLTUuOTQ3IDIuNy01LjU1OCAzLjUzLTYuMzggOS4zMzgtMi4yMDcgMTQuNDM4IDEuODQyIDIuMjU2IDQuMjE2IDMuODQzIDYuODUgNC45OTZsMTcuNjAzIDcuODQzYy4xNDcuMDguMzA0LjEzMi40NjMuMTYybDMuNzE3IDIuNjgycy0zLjcgNDAuOTQ4IDMuMjQ2IDQzLjc4MWMtLjA2MS0uMDEtLjQxLS4wODItLjQxLS4wODJzLjcwNC43NjEgMi42MDMuNTM3YzEuNDU0LjI3IDEuMjYyLjIyNi4wNzQtLjAxIDIuNTgzLS4zMzQgNy4zMzctMi40OTcgMTUuNTc4LTEwLjc4NGE0Ny4zOTYgNDcuMzk2IDAgMCAwIDEuNzc2LTEuNjc2bDE3LjgtMTkuMjE3IDQuMTYzIDEuNDY1Yy4xNS4yMDcuMzY3LjM0LjcxNC40NDNsMTkuODIzIDYuMDMxYzIuNzA5LjgzNiA1LjM4OSAxLjQ0OCA4LjI3NyAxLjAyNiA1LjE1Ni0uNzU1IDguOTUxLTUgOC45LTEwLjE5Mi0uMDItMi4yOC0uODItNC4zMzktMS44Ny02LjMyNGwtMTMuMTI4LTI0Ljg5OGMtLjQxOC0uNzg3LS40MDUtMS4yOTYuMTk2LTJsMjIuMDU0LTI1LjkyMmMxLjQyOC0xLjcwMyAyLjcxNy0zLjUyOSAzLjQ2NS01LjY0NSAxLjY0My00LjY3LS40ODItOC4zODItNS4zMy05LjI4OS0yLjIyOS0uMzk4LTQuNDI3LS4xODgtNi42LjM4NWwtMzEuNTk3IDguMzk1Yy0uOTMuMjUtMS4zOS4wNzUtMS44OTUtLjc3MmwtMTIuOS0yMS40MzRjLS45NzUtMS42MTUtMi4xNC0zLjE5NC0zLjQ3Ny00LjUyN0M2Mi4yMTIuODkgNTkuOTE1LS4wNTkgNTcuNjQ2LjAwNHptLjk0NCAxOS43MzZjLjUxLjM1OC43NjguNzI3IDEuMDEgMS4xMjVsMTMuODggMjMuMTNjLjM4Mi42MjguNzI1Ljg1IDEuNDg1LjY0OGwyNC40NDMtNi40OTcgNS44ODUtMS41NGMtLjA4Ny40OTMtLjMwMi43OS0uNTM3IDEuMDY4bC0yMC4xNiAyMy42NzJjLS41Ny42ODgtLjYyMyAxLjE3LS4xOTQgMS45NzZsMTIuNzQzIDI0LjE2LjU4NSAxLjIzNy0uMDE1LjAyLTIyLjcyNy02LjI2NC0uMDA2LS4wMTgtNC4yOTgtMS4yMDUtMjUuNDkzIDI4LjI1NiA0LjY2My0zNy4xNS00LjE4NC0xLjgyLjAwOC0uMDA3LTIzLjY3NC05LjRjLjQ1NC0uNDEzLjg2LS41ODUgMS4yODUtLjcxN2wyOC43NzctOS4wOTZjLjY3Ni0uMjEgMS4wNjEtLjQ3IDEuMTI1LTEuMjQybC40MDMtMi4zNTUgMy44NzUtMjEuODA3IDEuMTItNi4xNzR6Ii8%2BPC9zdmc%2B" alt="Apache Spark">
  <img src="https://img.shields.io/badge/Bash-Linux-4EAA25?style=for-the-badge&labelColor=1F2328&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyBmaWxsPSIjNEVBQTI1IiByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dGl0bGU%2BR05VIEJhc2g8L3RpdGxlPjxwYXRoIGQ9Ik0yMS4wMzgsNC45bC03LjU3Ny00LjQ5OEMxMy4wMDksMC4xMzQsMTIuNTA1LDAsMTIsMGMtMC41MDUsMC0xLjAwOSwwLjEzNC0xLjQ2MiwwLjQwM0wyLjk2MSw0LjkgQzIuMDU3LDUuNDM3LDEuNSw2LjQyOSwxLjUsNy41MDN2OC45OTVjMCwxLjA3MywwLjU1NywyLjA2NiwxLjQ2MiwyLjYwM2w3LjU3Nyw0LjQ5N0MxMC45OTEsMjMuODY2LDExLjQ5NSwyNCwxMiwyNCBjMC41MDUsMCwxLjAwOS0wLjEzNCwxLjQ2MS0wLjQwMmw3LjU3Ny00LjQ5N2MwLjkwNC0wLjUzNywxLjQ2Mi0xLjUyOSwxLjQ2Mi0yLjYwM1Y3LjUwM0MyMi41LDYuNDI5LDIxLjk0Myw1LjQzNywyMS4wMzgsNC45eiBNMTUuMTcsMTguOTQ2bDAuMDEzLDAuNjQ2YzAuMDAxLDAuMDc4LTAuMDUsMC4xNjctMC4xMTEsMC4xOThsLTAuMzgzLDAuMjJjLTAuMDYxLDAuMDMxLTAuMTExLTAuMDA3LTAuMTEyLTAuMDg1TDE0LjU3LDE5LjI5IGMtMC4zMjgsMC4xMzYtMC42NiwwLjE2OS0wLjg3MiwwLjA4NGMtMC4wNC0wLjAxNi0wLjA1Ny0wLjA3NS0wLjA0MS0wLjE0MmwwLjEzOS0wLjU4NGMwLjAxMS0wLjA0NiwwLjAzNi0wLjA5MiwwLjA2OS0wLjEyMSBjMC4wMTItMC4wMTEsMC4wMjQtMC4wMiwwLjAzNi0wLjAyNmMwLjAyMi0wLjAxMSwwLjA0My0wLjAxNCwwLjA2Mi0wLjAwNmMwLjIyOSwwLjA3NywwLjUyMSwwLjA0MSwwLjgwMi0wLjEwMSBjMC4zNTctMC4xODEsMC41OTYtMC41NDUsMC41OTItMC45MDdjLTAuMDAzLTAuMzI4LTAuMTgxLTAuNDY1LTAuNjEzLTAuNDY4Yy0wLjU1LDAuMDAxLTEuMDY0LTAuMTA3LTEuMDcyLTAuOTE3IGMtMC4wMDctMC42NjcsMC4zNC0xLjM2MSwwLjg4OS0xLjhsLTAuMDA3LTAuNjUyYy0wLjAwMS0wLjA4LDAuMDQ4LTAuMTY4LDAuMTExLTAuMmwwLjM3LTAuMjM2IGMwLjA2MS0wLjAzMSwwLjExMSwwLjAwNywwLjExMiwwLjA4N2wwLjAwNiwwLjY1M2MwLjI3My0wLjEwOSwwLjUxMS0wLjEzOCwwLjcyNi0wLjA4OGMwLjA0NywwLjAxMiwwLjA2NywwLjA3NiwwLjA0OCwwLjE1MSBsLTAuMTQ0LDAuNTc4Yy0wLjAxMSwwLjA0NC0wLjAzNiwwLjA4OC0wLjA2NSwwLjExNmMtMC4wMTIsMC4wMTItMC4wMjUsMC4wMjEtMC4wMzgsMC4wMjhjLTAuMDE5LDAuMDEtMC4wMzgsMC4wMTMtMC4wNTcsMC4wMDkgYy0wLjA5OC0wLjAyMi0wLjMzMi0wLjA3My0wLjY5OSwwLjExM2MtMC4zODUsMC4xOTUtMC41MiwwLjUzLTAuNTE3LDAuNzc4YzAuMDAzLDAuMjk3LDAuMTU1LDAuMzg3LDAuNjgxLDAuMzk2IGMwLjcsMC4wMTIsMS4wMDMsMC4zMTgsMS4wMSwxLjAyM0MxNi4xMDUsMTcuNzQ3LDE1LjczNiwxOC40OTEsMTUuMTcsMTguOTQ2eiBNMTkuMTQzLDE3Ljg1OWMwLDAuMDYtMC4wMDgsMC4xMTYtMC4wNTgsMC4xNDUgbC0xLjkxNiwxLjE2NGMtMC4wNSwwLjAyOS0wLjA5LDAuMDA0LTAuMDktMC4wNTZ2LTAuNDk0YzAtMC4wNiwwLjAzNy0wLjA5MywwLjA4Ny0wLjEyMmwxLjg4Ny0xLjEyOSBjMC4wNS0wLjAyOSwwLjA5LTAuMDA0LDAuMDksMC4wNTZWMTcuODU5eiBNMjAuNDU5LDYuNzk3bC03LjE2OCw0LjQyN2MtMC44OTQsMC41MjMtMS41NTMsMS4xMDktMS41NTMsMi4xODd2OC44MzMgYzAsMC42NDUsMC4yNiwxLjA2MywwLjY2LDEuMTg0Yy0wLjEzMSwwLjAyMy0wLjI2NCwwLjAzOS0wLjM5OCwwLjAzOWMtMC40MiwwLTAuODMzLTAuMTE0LTEuMTk3LTAuMzNMMy4yMjYsMTguNjQgYy0wLjc0MS0wLjQ0LTEuMjAxLTEuMjYxLTEuMjAxLTIuMTQyVjcuNTAzYzAtMC44ODEsMC40Ni0xLjcwMiwxLjIwMS0yLjE0Mmw3LjU3Ny00LjQ5OGMwLjM2My0wLjIxNiwwLjc3Ny0wLjMzLDEuMTk3LTAuMzMgYzAuNDE5LDAsMC44MzMsMC4xMTQsMS4xOTcsMC4zM2w3LjU3Nyw0LjQ5OGMwLjYyNCwwLjM3MSwxLjA0NiwxLjAxMywxLjE2NCwxLjczMkMyMS42ODYsNi41NTcsMjEuMTIsNi40MTEsMjAuNDU5LDYuNzk3eiIvPjwvc3ZnPg%3D%3D" alt="Bash">
  <img src="https://img.shields.io/badge/PowerShell-WSL-5391FE?style=for-the-badge&labelColor=1F2328&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbDpzcGFjZT0icHJlc2VydmUiIHZpZXdCb3g9IjAgMCAxMjggMTI4Ij48bGluZWFyR3JhZGllbnQgaWQ9ImEiIHgxPSI5Ni4zMDYiIHgyPSIyNS40NTQiIHkxPSIzNS4xNDQiIHkyPSI5OC40MzEiIGdyYWRpZW50VHJhbnNmb3JtPSJtYXRyaXgoMSAwIDAgLTEgMCAxMjgpIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSI%2BPHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjYTljOGZmIi8%2BPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjYzdlNmZmIi8%2BPC9saW5lYXJHcmFkaWVudD48cGF0aCBmaWxsPSJ1cmwoI2EpIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik03LjIgMTEwLjVjLTEuNyAwLTMuMS0uNy00LjEtMS45LTEtMS4yLTEuMy0yLjktLjktNC42bDE4LjYtODAuNWMuOC0zLjQgNC02IDcuNC02aDkyLjZjMS43IDAgMy4xLjcgNC4xIDEuOSAxIDEuMiAxLjMgMi45LjkgNC42bC0xOC42IDgwLjVjLS44IDMuNC00IDYtNy40IDZINy4yeiIgY2xpcC1ydWxlPSJldmVub2RkIiBvcGFjaXR5PSIuOCIvPjxsaW5lYXJHcmFkaWVudCBpZD0iYiIgeDE9IjI1LjMzNiIgeDI9Ijk0LjU2OSIgeTE9Ijk4LjMzIiB5Mj0iMzYuODQ3IiBncmFkaWVudFRyYW5zZm9ybT0ibWF0cml4KDEgMCAwIC0xIDAgMTI4KSIgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiPjxzdG9wIG9mZnNldD0iMCIgc3RvcC1jb2xvcj0iIzJkNDY2NCIvPjxzdG9wIG9mZnNldD0iLjE2OSIgc3RvcC1jb2xvcj0iIzI5NDA1YiIvPjxzdG9wIG9mZnNldD0iLjQ0NSIgc3RvcC1jb2xvcj0iIzFlMmY0MyIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMGMxMzFiIi8%2BPHN0b3Agb2Zmc2V0PSIxIi8%2BPC9saW5lYXJHcmFkaWVudD48cGF0aCBmaWxsPSJ1cmwoI2IpIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0xMjAuMyAxOC41SDI4LjVjLTIuOSAwLTUuNyAyLjMtNi40IDUuMkwzLjcgMTA0LjNjLS43IDIuOSAxLjEgNS4yIDQgNS4yaDkxLjhjMi45IDAgNS43LTIuMyA2LjQtNS4ybDE4LjQtODAuNWMuNy0yLjktMS4xLTUuMy00LTUuM3oiIGNsaXAtcnVsZT0iZXZlbm9kZCIvPjxwYXRoIGZpbGw9IiMyQzU1OTEiIGZpbGwtcnVsZT0iZXZlbm9kZCIgZD0iTTY0LjIgODguM2gyMi4zYzIuNiAwIDQuNyAyLjIgNC43IDQuOXMtMi4xIDQuOS00LjcgNC45SDY0LjJjLTIuNiAwLTQuNy0yLjItNC43LTQuOXMyLjEtNC45IDQuNy00Ljl6TTc4LjcgNjYuNWMtLjQuOC0xLjIgMS42LTIuNiAyLjZMMzQuNiA5OC45Yy0yLjMgMS42LTUuNSAxLTcuMy0xLjQtMS43LTIuNC0xLjMtNS43LjktNy4zbDM3LjQtMjcuMXYtLjZsLTIzLjUtMjVjLTEuOS0yLTEuNy01LjMuNC03LjQgMi4yLTIgNS41LTIgNy40IDBsMjguMiAzMGMxLjcgMS45IDEuOCA0LjUuNiA2LjR6IiBjbGlwLXJ1bGU9ImV2ZW5vZGQiLz48cGF0aCBmaWxsPSIjRkZGIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik03Ny42IDY1LjVjLS40LjgtMS4yIDEuNi0yLjYgMi42TDMzLjYgOTcuOWMtMi4zIDEuNi01LjUgMS03LjMtMS40LTEuNy0yLjQtMS4zLTUuNy45LTcuM2wzNy40LTI3LjF2LS42bC0yMy41LTI1Yy0xLjktMi0xLjctNS4zLjQtNy40IDIuMi0yIDUuNS0yIDcuNCAwbDI4LjIgMzBjMS43IDEuOCAxLjggNC40LjUgNi40ek02My41IDg3LjhoMjIuM2MyLjYgMCA0LjcgMi4xIDQuNyA0LjYgMCAyLjYtMi4xIDQuNi00LjcgNC42SDYzLjVjLTIuNiAwLTQuNy0yLjEtNC43LTQuNiAwLTIuNiAyLjEtNC42IDQuNy00LjZ6IiBjbGlwLXJ1bGU9ImV2ZW5vZGQiLz48L3N2Zz4%3D" alt="PowerShell">
</p>

</div>

AI agents are getting direct access to production tools such as Kubernetes, Airflow, dbt, OpenMetadata and Spark. Without a single control point, each MCP server ends up with its own authentication, nobody can say which agent called what, and a compromised pod can call any backend directly.

This project puts **[agentgateway](https://agentgateway.dev)** in front of five MCP servers on a local Kubernetes cluster and builds the full trust chain **from configuration only, with no custom gateway code**:

| | |
|---|---|
| 🔐 **Authenticate** | Every call carries a Keycloak JWT; invalid tokens get `401` |
| 🧰 **Authorize per tool** | Each agent *sees* and *calls* only the tools its roles allow (deny by default) |
| 🪪 **Forward identity** | Backends learn who called; the caller's token never leaves the gateway |
| 🧱 **Isolate the network** | NetworkPolicy makes the gateway the only way into the backends |
| 📊 **Audit** | Every allow and deny is logged and charted in Grafana |

---

## Architecture

<p align="center">
  <img src="report/images/system-architecture.png" alt="System architecture: clients, agentgateway data plane with five checks, Keycloak, MCP backends and observability on kind" width="900">
</p>

Every tool call passes five checks in the gateway's data plane:

| # | Check | Question it answers | Configured in |
|:-:|---|---|---|
| 01 | **Check token** | Is the JWT genuine, unexpired and issued for `mcp-gateway`? | [`deploy/auth/`](deploy/auth/) |
| 02 | **Filter tools** | May these roles see and call this `{target}_{tool}`? | [`rbac/tool-access.yaml`](rbac/tool-access.yaml) |
| 03 | **Pass identity** | What does the backend learn? Headers set from verified claims; token dropped | [`deploy/auth/`](deploy/auth/) |
| 04 | **Swap token** | OpenMetadata gets an exchanged, audience-scoped token *(designed)* | [`deploy/identity/`](deploy/identity/) |
| 05 | **Log** | Who called which tool, and was it allowed? | [`observability/access-logs/`](observability/access-logs/) |

Network isolation sits underneath all five: [`deploy/network/`](deploy/network/) only lets the gateway namespace reach `mcp`.

<details>
<summary><b>Request sequence for a single tool call</b></summary>

```mermaid
sequenceDiagram
    autonumber
    participant A as AI agent
    participant K as Keycloak
    participant G as agentgateway
    participant B as Backend (e.g. radar)

    A->>K: client credentials (client_id, secret)
    K-->>A: access token (aud=mcp-gateway, roles=[...])
    A->>G: tools/call radar_list_namespaces + Bearer token
    G->>K: fetch JWKS (cached)
    G->>G: verify signature, issuer, audience
    G->>G: any rule matching roles + target + tool?
    alt no rule matches
        G-->>A: Unknown tool (hidden and denied)
    else allowed
        G->>B: list_namespaces + x-forwarded-user / x-agent-id (token removed)
        B-->>G: result
        G-->>A: result
    end
    G->>G: access log: agent, roles, target, tool, status
```

</details>

### Docker map

Everything runs on one Docker host: the kind node holds the gateway, Keycloak, mocks, radar and the observability stack; OpenMetadata and Spark History run as separate Compose projects on the same `kind` network.

<p align="center">
  <img src="report/images/docker-map.png" alt="Docker map of the kind node, OpenMetadata and Spark History compose projects with ports and volumes" width="900">
  <br><sub>Containers, exposed ports and volumes. Solid arrows: published ports; dashed arrows: traffic and storage.</sub>
</p>

---

## Tool catalog

One endpoint (`/mcp`) multiplexes five targets. Tools reach clients as `{target}_{tool}`, e.g. `radar_list_namespaces`.

| Target | Tools | Read | Write / Execute | Backend |
|---|:-:|:-:|:-:|---|
| `radar` | 4 | 3 | 1 | real (Helm) or mock |
| `spark-history` | 3 | 3 | – | real (Docker) or mock |
| `openmetadata` | 4 | 3 | 1 | real (Docker) or mock |
| `dbt` | 5 | 4 | 1 | mock |
| `airflow` | 5 | 3 | 2 | mock |
| **Total** | **21** | | | |

Mock write tools are write-*shaped* but have no side effects.

## AI agent identities

Each agent is its own confidential Keycloak client (OAuth client credentials). Roles are split by **capability per system** (viewer vs. operator/editor), not by job title, so an agent only gets what it needs.

| Agent | Roles | Tools |
|---|---|:-:|
| `cluster-observer-agent` | `kube_viewer` | 3 |
| `incident-response-agent` | `kube_operator`, `spark_viewer` | 7 |
| `spark-diagnostic-agent` | `spark_viewer` | 3 |
| `metadata-discovery-agent` | `metadata_viewer` | 3 |
| `metadata-steward-agent` | `metadata_editor` | 4 |
| `dbt-quality-agent` | `dbt_operator` | 5 |
| `airflow-monitor-agent` | `airflow_viewer` | 3 |
| `airflow-operator-agent` | `airflow_operator` | 5 |
| `platform-admin-agent` | `platform_admin` | 21 |
| `no-access-agent` | *(none)* | 0 |

The machine-readable contract is [`tests/expected/agent-tool-access.json`](tests/expected/agent-tool-access.json). Rules are OR-ed: an agent with several roles gets the union.

---

## Results

All numbers come from saved test output in [`evidence/`](evidence/).

| Check | Expected | Measured |
|---|:-:|:-:|
| Tools callable through `/mcp` with correct prefix | 21 | **21** |
| Agent × tool cells matching the contract in `tools/list` | 210 | **210** |
| Agents with the correct `roles` claim | 10 | **10** |
| Out-of-scope calls blocked | 9 | **9** |
| Calls with an audit record | 18 | **18** |
| Pod in `default` reaching a backend | blocked | **timeout** |
| *Warm start*: apply all layers (mean of 5) | – | **4.15 s** |
| *Warm start*: ready for agents (mean of 5) | – | **≈ 5.2 s** |

<p align="center">
  <img src="report/images/grafana-allow-deny.png" alt="Grafana allow/deny dashboard showing 9 allowed and 9 denied tool calls by user, role, target and tool" width="900">
  <br><sub>Grafana allow/deny dashboard after one RBAC test run: 9 allowed, 9 denied, broken down by agent, role, target and tool.</sub>
</p>

---

## Quick start

**Requirements:** `kind`, `kubectl`, `helm`, Docker with Compose (~8 GB memory), Node 22.19+, `curl`, `jq`; Python with `mcp==1.30.0` for the Python tests.

```bash
./bootstrap.sh     # once: kind cluster, Gateway API CRDs + agentgateway, mock image
./run.sh           # every time: apply all layers;  ./run.sh test  also runs the tests
```

On Windows, run the same steps through WSL with PowerShell:

```powershell
.\ops\up.ps1       # start everything
.\ops\down.ps1     # delete the cluster
```

Both paths are idempotent. The first run downloads about 4 GB. See **[QUICKSTART.md](QUICKSTART.md)** for the manual steps, checks, cleanup and troubleshooting.

| Service | Address |
|---|---|
| MCP endpoint | `http://localhost:8080/mcp` (with `Authorization: Bearer <token>`) |
| Keycloak | `http://localhost:8002` (`admin` / `admin`) |
| Grafana | `http://localhost:3000` (`admin` / `admin`) |
| OpenMetadata | `http://localhost:8585` |
| agentgateway admin UI (read-only) | `http://localhost:15000/ui/` |

> [!WARNING]
> The default credentials above and the test-user password `password` are for local use only. Change them before running anywhere else.

### Try it

```bash
TOKEN=$(scripts/get-token.sh engineer.user)
npx -y @modelcontextprotocol/inspector@0.21.2 --cli "http://localhost:8080/mcp" \
  --transport http --header "Authorization: Bearer $TOKEN" --method tools/list
```

Always call the gateway, never a backend directly.

### Tests

```bash
node tests/static_contract_test.mjs   # manifests vs. contract, no cluster needed
python servers/smoke_test.py          # mocks locally, identity headers
python tests/gateway_smoke.py         # all 21 tools through localhost:8080
python tests/agent_rbac_smoke.py      # 10 agents: claims, visible tools, allowed/denied calls
bash scripts/run-tests.sh             # everything against the running cluster
```

---

## Repository layout

```
deploy/
  agentgateway/      Gateway, HTTPRoute, AgentgatewayBackend (5 targets)
  auth/              JWT validation + identity headers
  identity/          token exchange (OpenMetadata)
  keycloak/          Keycloak, realm and agent setup scripts
  network/           NetworkPolicy: backends accept only the gateway
  real-servers/      real radar (Helm), OpenMetadata and Spark History (Docker)
  cluster/           kind config and CNI notes
rbac/                tool-access.yaml: the role → tool policy (source of truth)
servers/             FastMCP mocks, one folder per target; k8s/mocks.yaml deploys them
observability/       access-log fields, Loki/Alloy/Grafana dashboard
tests/               contract, smoke and RBAC tests; expected/ holds the matrices
scripts/  ops/       Linux (bash) and Windows (PowerShell) automation
evidence/            saved outputs behind every reported number
docs/                design notes, observability review, diagrams/
report/              internship report (LaTeX)
```

### Common changes

| I want to… | Change |
|---|---|
| Give a role more tools | `rbac/tool-access.yaml` **and** `tests/expected/` in the same commit |
| Add an agent | New Keycloak client + roles, then add it to `tests/expected/agent-tool-access.json` |
| Swap a mock for a real server | `host`/`port` of the target in `deploy/agentgateway/AgentgatewayBackend.yaml`; name and rules stay |
| Add or rename a tool | `servers/<target>/server.py`, backend, RBAC, expected matrix, `CASES` in `tests/gateway_smoke.py`, and the 21-tool count |

Keep a target's name identical across its mock folder, Service, backend target, RBAC rules and tests.

---

## Scope and limitations

This is a proof of concept on a local kind cluster, not a production deployment.

- Token exchange for OpenMetadata and per-resource authorization on real backends are **designed but not complete**.
- Agents acting **on behalf of a human user** (delegated identity) is out of scope.
- Only *warm start* was measured; *cold start* and gateway latency under load were not.

## Documentation

| Document | Content |
|---|---|
| [QUICKSTART.md](QUICKSTART.md) | Setup, checks, cleanup, troubleshooting |
| [docs/ai-agent-tool-access.md](docs/ai-agent-tool-access.md) | Agent identities, capability roles, 21-tool matrix |
| [rbac/policy-overlap-experiment.md](rbac/policy-overlap-experiment.md) | Why everything is one `Allow` policy |
| [docs/agentgateway-observability-review.md](docs/agentgateway-observability-review.md) | Logs, metrics, traces and denials on agentgateway v1.5.0 |
| [deploy/real-servers/README.md](deploy/real-servers/README.md) | Real radar, OpenMetadata and Spark History, and their limits |
| [docs/diagrams/](docs/diagrams/) | Editable draw.io diagrams and the numbered system flow |

## Authors

Internship project at VietCredit, Faculty of Information Systems, University of Economics and Law (VNU-HCM), 2026.

- **Vòng Hữu Quân**
- **Nguyễn Trần Thái Huy**

Supervisor: Assoc. Prof. Dr. Lê Hoành Sử.

## Acknowledgements

Special thanks to our project mentor **[thanhENC](https://github.com/thanhENC)** for proposing the problem, guiding the design of the gateway and agent access model, and reviewing our work throughout the internship.
