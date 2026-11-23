# AZ-104 Lab 06 – Implement Network Traffic Management (CLI + Bicep)

Hands-on lab from the Microsoft AZ-104 course, completed with **Azure CLI, ARM templates and Bicep** instead of the portal.
Goal: distribute web traffic across VMs using **Azure Load Balancer (Layer 4)** and **Application Gateway (Layer 7)** with path-based routing.

## Architecture

| Resource | Details |
|---|---|
| Resource group | `az104-rg6` (East US) |
| Virtual network | `az104-06-vnet1` – subnet0/1/2 (10.60.0-2.0/24), subnet-appgw (10.60.3.224/27) |
| VMs | `az104-06-vm0` (10.60.0.4), `vm1` (10.60.1.4), `vm2` (10.60.2.4) – Standard_D2s_v3, IIS |
| Load Balancer | `az104-lb` – Standard, public IP `az104-lbpip`, backend: vm0 + vm1 |
| Application Gateway | `az104-appgw` – Standard_v2, 2 instances, public IP `az104-gwpip` |

## Tasks

| Task | What was done | File |
|---|---|---|
| 1 | Deployed VNet, NSG and 3 VMs from an ARM template (VM size changed v5 → v3 with `sed` + parameter override) | `cli/task1-deploy-vms.sh`, `templates/` |
| 2 | Created Standard Load Balancer: frontend, backend pool (NIC-based), TCP health probe (port 80), LB rule (80 → 80). Tested with `curl` | `cli/task2-load-balancer.sh` |
| 3 | Created Application Gateway with path-based routing: `/image/*` → vm1, `/video/*` → vm2, default → vm1 + vm2 | `bicep/appgw.bicep` |

## Key concepts

- **Load Balancer vs Application Gateway** – LB works at Layer 4 (IP/port), App Gateway at Layer 7 (HTTP paths, host headers, WAF, SSL termination).
- **Health probes** – traffic is only sent to backends that pass the probe.
- **Parameter precedence** – a value in the parameters file overrides the template default, so the VM size had to be changed in both places.
- **Path-based routing** – one listener, different backend pools per URL path.
- **App Gateway needs a dedicated subnet** (/27 or larger).
- **Why Bicep for Task 3** – `az network application-gateway create` uses default names (`rule1`, `appGatewayHttpListener`). Bicep allowed exact names (`az104-listener`, `az104-gwrule`) in a single deployment instead of several slow updates.

## Real-world issues I hit

- **Typos in `curl -o` file names** overwrote the template with the parameters file – fixed by re-downloading both files and checking sizes with `ls -l`.
- **404 file (14 bytes)** – a typo in the raw GitHub URL saved "404: Not Found" as JSON. Lesson: always verify downloads with `cat` / `ls -l`.
- **`git push` → `src refspec main does not match any`** – no commit existed yet in the empty repo (`git add.` without a space). Fixed with `git add .`, commit, `git push -u origin main`.
- **Unclosed quote → `>` prompt** – bash waits for the closing `"`. Fixed with Ctrl+C and retyping.
- **`curl https://` hung** – the LB only listens on port 80 (HTTP). Used `http://` and `--max-time`.
- **Application Gateway takes ~10 minutes to deploy** – the lab time ran out before testing. Lesson: start long-running deployments first and use `--no-wait`.

## Skills demonstrated

Azure CLI · Bash scripting · ARM templates · Bicep · Azure Load Balancer · Application Gateway · Git/GitHub
