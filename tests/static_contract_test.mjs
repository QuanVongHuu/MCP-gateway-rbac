import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), "utf8");

const matrix = JSON.parse(
  read("tests/expected/agent-tool-access.json"),
);
const gatewaySmoke = read("tests/gateway_smoke.py");
const policy = read("rbac/tool-access.yaml");
const realmYaml = read("deploy/keycloak/realm-config.yaml");

const casesBody = gatewaySmoke.match(/CASES = \{([\s\S]*?)\n\}\n\n\nasync function|CASES = \{([\s\S]*?)\n\}\n\n\nasync def/);
if (!casesBody) throw new Error("Could not locate CASES in tests/gateway_smoke.py");
const smokeTools = [...(casesBody[1] ?? casesBody[2]).matchAll(/^    "([^"]+)":/gm)]
  .map((match) => match[1])
  .sort();
const matrixTools = [...matrix.all_tools].sort();
if (JSON.stringify(smokeTools) !== JSON.stringify(matrixTools)) {
  throw new Error(`Tool catalog mismatch\nsmoke=${smokeTools}\nmatrix=${matrixTools}`);
}

for (const agent of matrix.agents) {
  for (const role of agent.roles) {
    if (!policy.includes(`"${role}" in jwt.roles`)) {
      throw new Error(`${agent.client_id}: role ${role} is absent from tool policy`);
    }
  }
  const unknown = agent.tools.filter((tool) => !matrix.all_tools.includes(tool));
  if (unknown.length) throw new Error(`${agent.client_id}: unknown tools ${unknown}`);
}

const marker = "  mcp-realm.json: |\n";
const realmStart = realmYaml.indexOf(marker);
if (realmStart < 0) throw new Error("Could not locate embedded realm JSON");
const realmText = realmYaml
  .slice(realmStart + marker.length)
  .split("\n")
  .map((line) => line.replace(/^    /, ""))
  .join("\n");
const realm = JSON.parse(realmText);
const clients = new Set(realm.clients.map((client) => client.clientId));
const users = new Map(
  realm.users.map((user) => [user.serviceAccountClientId, user.clientRoles?.["mcp-gateway"] ?? []]),
);

for (const agent of matrix.agents) {
  if (!clients.has(agent.client_id)) {
    throw new Error(`${agent.client_id}: missing Keycloak client`);
  }
  const actualRoles = [...(users.get(agent.client_id) ?? [])].sort();
  const expectedRoles = [...agent.roles].sort();
  if (JSON.stringify(actualRoles) !== JSON.stringify(expectedRoles)) {
    throw new Error(
      `${agent.client_id}: realm roles ${actualRoles} != matrix roles ${expectedRoles}`,
    );
  }
}

console.log(`static_contract=PASS tools=${matrixTools.length} agents=${matrix.agents.length}`);
