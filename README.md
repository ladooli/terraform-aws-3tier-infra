<a id="readme-top"></a>

<div align="center">

<h1>terraform-aws-3tier-infra</h1>

<p>
A three-tier AWS network built entirely with Terraform, serving a containerized
Node.js application from a private container registry.
</p>

<a href="#architecture">Architecture</a>
·
<a href="#getting-started">Getting Started</a>
·
<a href="#what-i-learned">What I Learned</a>

</div>

<details>
<summary>Table of Contents</summary>

- [About The Project](#about-the-project)
- [Built With](#built-with)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Security Notes](#security-notes)
- [What I Learned](#what-i-learned)
- [Roadmap](#roadmap)
- [License](#license)
- [Contact](#contact)

</details>

---

## About The Project

This project provisions a complete AWS environment from scratch using Terraform,
then runs a small containerized web application on it.

The goal was to practise infrastructure as code the way it is used in production:
no resource is created by hand in the AWS console, the whole environment can be
torn down and rebuilt from a single command, and application servers never have a
public IP address.

What the stack does end to end:

- Terraform builds a VPC with three subnet tiers across two availability zones
- Two EC2 instances boot in private subnets and configure themselves on first start
- On boot they authenticate to a private ECR registry using an IAM instance profile,
  pull the application and reverse proxy images, and start them with Docker Compose
- A Network Load Balancer in the public subnets distributes incoming traffic
  across both instances
- A bastion host is the only way to reach the private instances over SSH

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Built With

* [![Terraform][terraform-shield]][terraform-url]
* [![AWS][aws-shield]][aws-url]
* [![Docker][docker-shield]][docker-url]
* [![Node.js][node-shield]][node-url]
* [![Express][express-shield]][express-url]
* [![Nginx][nginx-shield]][nginx-url]
* [![Linux][linux-shield]][linux-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Architecture

```
                            Internet
                                │
                    ┌───────────┴───────────┐
                    │  Network Load Balancer │  (public subnets)
                    └───────────┬───────────┘
                                │
┌──────────────── VPC 10.0.0.0/16 · eu-north-1 ─────────────────────┐
│                                                                   │
│  PUBLIC          10.0.1.0/24 (AZ a)      10.0.2.0/24 (AZ b)        │
│    ├─ NLB nodes                                                   │
│    ├─ Bastion host (SSH entry point)                              │
│    └─ NAT Gateway                                                 │
│                                                                   │
│  PRIVATE APP     10.0.10.0/24 (AZ a)     10.0.11.0/24 (AZ b)       │
│    ├─ server-1: nginx + app1 + app2       ├─ server-2: same        │
│    └─ outbound traffic via NAT Gateway                             │
│                                                                   │
│  PRIVATE DB      10.0.20.0/24 (AZ a)     10.0.21.0/24 (AZ b)       │
│    └─ reserved for a future managed database                      │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘

  ECR (private) ──► instances pull images through the NAT Gateway,
                    authenticated by an IAM instance profile
```

**Design decisions**

- **Private application servers.** The EC2 instances have no public IP. Inbound
  traffic arrives only through the load balancer; outbound traffic for package
  installs and image pulls goes through the NAT Gateway.
- **No static credentials on the instances.** ECR access comes from an IAM role
  attached through an instance profile, so no access keys are stored anywhere.
- **Self-configuring instances.** A `user_data` template installs Docker, writes a
  `docker-compose.yml` and starts the containers, so replacing an instance needs no
  manual steps.
- **Two availability zones.** Every subnet tier is duplicated across two AZs, so the
  loss of one zone does not take the application down.
- **A separate database tier that is currently empty.** The subnets and routing are
  in place for a managed database to be added without touching the network layer.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Project Structure

```
terraform-aws-3tier-infra/
├── app/                       # Node.js / Express application
│   ├── Dockerfile
│   ├── index.js
│   └── package.json
├── nginx/                     # Reverse proxy in front of the app containers
│   ├── Dockerfile
│   └── nginx.conf
├── scripts/
│   └── build_and_push.sh      # Builds both images and pushes them to ECR
└── terraform/
    ├── main.tf                # Providers, AMI and account lookups
    ├── variables.tf           # Input variables
    ├── outputs.tf             # Endpoints, IPs and ready-made SSH commands
    ├── vpc.tf                 # VPC, Internet Gateway, NAT Gateway, route tables
    ├── subnets.tf             # Three subnet tiers across two AZs
    ├── security_groups.tf     # Bastion and application server rules
    ├── ec2.tf                 # Bastion and application instances
    ├── ecr.tf                 # Private registries with lifecycle policies
    ├── iam.tf                 # IAM role and instance profile for ECR access
    ├── load_balancer.tf       # NLB, target group and listener
    └── templates/
        └── user_data.sh.tpl   # First-boot configuration script
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Getting Started

### Prerequisites

- An AWS account with programmatic access configured

  ```sh
  aws configure
  ```

- Terraform 1.3 or newer

  ```sh
  terraform -version
  ```

- Docker, for building and pushing the application images

- An EC2 key pair created in the target region. Download the `.pem` file and keep it
  out of version control.

### Installation

1. Clone the repository

   ```sh
   git clone https://github.com/<your-username>/terraform-aws-3tier-infra.git
   cd terraform-aws-3tier-infra
   ```

2. Set your key pair name and restrict SSH access to your own IP address in
   `terraform/variables.tf`, or pass them on the command line in the next step.

3. Create the infrastructure

   ```sh
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

   The ECR repositories are created here, but they are still empty, so the
   instances have nothing to pull yet.

4. Build and push the images

   ```sh
   cd ..
   ./scripts/build_and_push.sh
   ```

5. Recreate the instances so they pull the images that now exist

   ```sh
   cd terraform
   terraform taint 'aws_instance.server[0]'
   terraform taint 'aws_instance.server[1]'
   terraform apply
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

Open the application through the load balancer:

```sh
terraform output -raw app_url
```

Each request is answered by one of the containers, and the response contains the
hostname that served it, so repeated calls show the load balancing in action:

```json
{
  "message": "Hello World!",
  "hostname": "a1b2c3d4e5f6",
  "port": "3000",
  "timestamp": "2026-10-12T09:41:07.882Z"
}
```

Connect to a private instance through the bastion host:

```sh
terraform output ssh_to_server_via_bastion
```

Tear everything down when you are finished:

```sh
terraform destroy
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Security Notes

- **State files are not committed.** `terraform.tfstate` records every resource
  attribute in plain text, including values that should not be public, so it is
  excluded in `.gitignore`. A production setup would store it in an S3 backend with
  state locking.
- **No private keys in the repository.** The EC2 key pair is created outside
  Terraform and the `.pem` file never enters version control.
- **SSH is meant to be restricted.** `ssh_allowed_cidr` defaults to `0.0.0.0/0` so
  the project runs after a clean clone, but it should be narrowed to a single
  address:

  ```sh
  terraform apply -var="ssh_allowed_cidr=203.0.113.4/32"
  ```

- **The NLB uses instance targets,** which preserve the original client IP. The
  application security group therefore allows HTTP from the internet rather than
  from the VPC range alone. Switching the target group to IP targets would allow a
  tighter rule.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## What I Learned

- How Terraform builds its dependency graph from resource references, and when an
  explicit `depends_on` is actually needed — the NAT Gateway has to exist before the
  private instances boot, or the image pull in `user_data` fails silently.
- Why an EBS-style AZ constraint matters when designing subnets: every tier has to
  exist in both availability zones for the load balancer to be able to fail over.
- The difference between granting permissions to a machine and to a person. The
  instances use an IAM role through an instance profile rather than access keys,
  which means nothing has to be rotated or stored.
- That a Terraform state file is sensitive by nature, not by accident, and that
  anything generating secrets inside Terraform ends up in it.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Roadmap

- [x] VPC with three subnet tiers across two availability zones
- [x] Private ECR registries with image lifecycle policies
- [x] Self-configuring EC2 instances via `user_data`
- [x] Network Load Balancer across both availability zones
- [ ] Remote state in S3 with DynamoDB locking
- [ ] Replace the bastion host with SSM Session Manager
- [ ] RDS instance in the database tier
- [ ] Auto Scaling Group instead of fixed instances
- [ ] HTTPS through an Application Load Balancer and an ACM certificate
- [ ] CI pipeline running `terraform fmt`, `validate` and `plan` on pull requests

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

Oliver — [LinkedIn](https://www.linkedin.com/in/your-profile)

Project link: [https://github.com/<your-username>/terraform-aws-3tier-infra](https://github.com/)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[terraform-shield]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white
[terraform-url]: https://www.terraform.io/
[aws-shield]: https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonwebservices&logoColor=white
[aws-url]: https://aws.amazon.com/
[docker-shield]: https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white
[docker-url]: https://www.docker.com/
[node-shield]: https://img.shields.io/badge/Node.js-5FA04E?style=for-the-badge&logo=nodedotjs&logoColor=white
[node-url]: https://nodejs.org/
[express-shield]: https://img.shields.io/badge/Express-000000?style=for-the-badge&logo=express&logoColor=white
[express-url]: https://expressjs.com/
[nginx-shield]: https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white
[nginx-url]: https://nginx.org/
[linux-shield]: https://img.shields.io/badge/Amazon%20Linux-FF9900?style=for-the-badge&logo=amazonwebservices&logoColor=white
[linux-url]: https://aws.amazon.com/linux/amazon-linux-2023/
