# Azure Deployment Tools Comparison

**azure-deploy Skill vs Azure MCP Tools**

*A neutral comparison for team decision-making*

---

## Executive Summary

| Aspect | azure-deploy Skill | Azure MCP Tools |
|--------|-------------------|-----------------|
| **Purpose** | Focused deployment workflow | Broad Azure operations platform |
| **Scope** | Static Web Apps, App Service, Functions | 20+ Azure services |
| **Approach** | Guided scripts with prompts | Flexible API-based tools |
| **Best For** | Quick, repeatable deployments | Complex Azure workflows |

**Bottom Line**: These tools are **complementary, not competing**. The azure-deploy skill excels at streamlined deployment workflows, while Azure MCP provides comprehensive Azure resource management. Teams can use both—or integrate them for enhanced capabilities.

---

## Feature Comparison

### Deployment Capabilities

| Capability | azure-deploy Skill | Azure MCP Tools |
|------------|-------------------|-----------------|
| **Static Web Apps deployment** | ✅ Full workflow | ⚠️ Via CLI generation |
| **App Service deployment** | ✅ Full workflow | ✅ `appservice` tools |
| **Container Apps** | ❌ Not supported | ✅ Via `deploy` tools |
| **Azure Functions** | ✅ Full workflow | ✅ `functionapp` tools |
| **AKS (Kubernetes)** | ❌ Not supported | ✅ `aks` tools |
| **Local preview** | ✅ Built-in | ❌ Not available |
| **Interactive resource selection** | ✅ Numbered menus | ⚠️ Requires parameters |

### Resource Management

| Capability | azure-deploy Skill | Azure MCP Tools |
|------------|-------------------|-----------------|
| **List existing resources** | ✅ Web Apps, Static Web Apps | ✅ All Azure resources |
| **Create resources** | ✅ App Service, Static Web Apps | ✅ Many services |
| **Query resource details** | ❌ Limited | ✅ Full API access |
| **Monitor/diagnostics** | ❌ Not included | ✅ `monitor`, `applens` |
| **Storage management** | ❌ Not included | ✅ `storage` tools |
| **Database operations** | ❌ Not included | ✅ `cosmos`, `postgres`, `mysql`, `sql` |

### Developer Experience

| Aspect | azure-deploy Skill | Azure MCP Tools |
|--------|-------------------|-----------------|
| **Learning curve** | Low — guided prompts | Medium — requires Azure knowledge |
| **Customization** | Edit shell scripts | Configure tool parameters |
| **Error handling** | Script-level messages | Structured API responses |
| **Authentication** | Azure CLI (`az login`) | Azure CLI (`az login`) |
| **CI/CD guidance** | ❌ Manual setup | ✅ `deploy_pipeline_guidance_get` |
| **IaC generation** | ❌ Not included | ✅ Bicep/Terraform rules |

---

## When to Use Each

### Use azure-deploy Skill When:

- ✅ Deploying a **static website** or **simple web app**
- ✅ Team needs a **quick, repeatable** deployment process
- ✅ Users are **not Azure experts** and need guidance
- ✅ You want **local preview** before deploying
- ✅ Standard Flask/Node.js/React projects

### Use Azure MCP Tools When:

- ✅ Working with **multiple Azure services** (databases, storage, functions)
- ✅ Need **post-deployment monitoring** and diagnostics
- ✅ Building **CI/CD pipelines** with infrastructure as code
- ✅ Querying or managing **existing Azure resources**
- ✅ Complex architectures (microservices, AKS, Container Apps)

### Use Both When:

- ✅ You want the skill's **simple deployment UX** with MCP's **resource discovery**
- ✅ Need deployment + **monitoring/diagnostics** capabilities
- ✅ Building a **hybrid workflow** for different team skill levels

---

## Pros and Cons

### azure-deploy Skill

| Pros | Cons |
|------|------|
| Simple, opinionated workflow | Limited to 3 Azure services |
| Interactive resource selection | No monitoring/diagnostics |
| Local preview built-in | No IaC or CI/CD generation |
| Low learning curve | Requires shell script knowledge to customize |
| Works offline (after az login) | No database or storage support |

### Azure MCP Tools

| Pros | Cons |
|------|------|
| Comprehensive Azure coverage (20+ services) | Steeper learning curve |
| Deployment planning and IaC guidance | No local preview capability |
| Monitoring, logging, and diagnostics | Requires more Azure knowledge |
| CI/CD pipeline guidance | Less guided—more parameters to specify |
| Scales to complex architectures | Can be overwhelming for simple deployments |

---

## Improvements & Recommendations

The azure-deploy skill could be enhanced by integrating Azure MCP tools to provide a more comprehensive deployment experience while maintaining its simple, guided workflow.

### Implementation Tasks

#### 🔴 High Priority

- [ ] **Post-Deployment Health Checks** *(Low effort, High impact)*
  - [ ] Query `azure-mcp-monitor` for initial application logs after deployment
  - [ ] Check `azure-mcp-resourcehealth` for resource status
  - [ ] Report deployment success with live URL verification
  - [ ] Add health check step to `deploy.sh` and `deploy_static.sh`

- [ ] **Pre-Deployment Validation** *(Medium effort, High impact)*
  - [ ] Check resource quotas with `azure-mcp-quota` before deployment
  - [ ] Verify target region availability
  - [ ] Validate resource group exists or can be created
  - [ ] Add validation step to deployment scripts

#### 🟡 Medium Priority

- [ ] **Smarter Resource Selection** *(Medium effort, Medium impact)*
  - [ ] Replace shell-based `az` commands in `select_webapp.sh` with MCP queries
  - [ ] Replace shell-based `az` commands in `select_static_webapp.sh` with MCP queries
  - [ ] Use `azure-mcp-appservice` for web app discovery
  - [ ] Use `azure-mcp-group_list` for resource group enumeration
  - [ ] Benefit: Structured data, better error handling

- [ ] **Deployment Troubleshooting** *(Low effort, Medium impact)*
  - [ ] Invoke `azure-mcp-applens` when deployments fail
  - [ ] Surface specific remediation steps from diagnostics
  - [ ] Add troubleshooting guidance to error output

#### 🟢 Low Priority

- [ ] **Intelligent Service Recommendation** *(Medium effort, Low impact)*
  - [ ] Use `azure-mcp-deploy` (`deploy_plan_get`) to analyze project structure
  - [ ] Recommend Static Web Apps vs App Service vs Container Apps
  - [ ] Generate architecture diagrams for complex projects

- [ ] **CI/CD Pipeline Generation** *(High effort, Extended capability)*
  - [ ] Integrate `azure-mcp-deploy` (`deploy_pipeline_guidance_get`)
  - [ ] Generate GitHub Actions workflows for automated deployments
  - [ ] Add `scripts/generate_pipeline.sh` command

### MCP Integration Reference

| Current Limitation | Azure MCP Solution | Status |
|--------------------|-------------------|--------|
| Manual resource discovery | `azure-mcp-subscription_list` + `azure-mcp-group_list` | ⬜ Not started |
| No pre-deployment validation | `azure-mcp-quota` + `azure-mcp-resourcehealth` | ⬜ Not started |
| Limited error troubleshooting | `azure-mcp-applens` | ⬜ Not started |
| No post-deployment monitoring | `azure-mcp-monitor` + `azure-mcp-deploy` (app logs) | ⬜ Not started |
| No architecture recommendations | `azure-mcp-deploy` (`deploy_plan_get`) | ⬜ Not started |
| No CI/CD support | `azure-mcp-deploy` (`deploy_pipeline_guidance_get`) | ⬜ Not started |

---

## Conclusion

The **azure-deploy skill** and **Azure MCP tools** serve different but complementary purposes:

- **azure-deploy** is ideal for teams that need a **simple, guided deployment experience** for static sites and web apps
- **Azure MCP** provides **comprehensive Azure operations** for teams working with complex cloud architectures

For maximum value, consider **integrating MCP capabilities into the azure-deploy skill** to combine the best of both: a simple deployment workflow enhanced with Azure's full platform intelligence.

---

*Document generated for team comparison purposes. Last updated: January 2026*
