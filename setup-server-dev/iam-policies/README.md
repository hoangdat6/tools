# IAM Policies for Infrastructure Team DN

Bộ IAM policies này được thiết kế để cấp quyền cho team Infrastructure DN quản lý dev server mà không cần quyền Administrator, đồng thời ngăn chặn privilege escalation.

## 📁 Cấu trúc Files

```
iam-policies/
├── README.md                        # Tài liệu này
├── infra-dn-services.json           # Policy 1: AWS Services
├── infra-dn-iam.json                # Policy 2: IAM + Deny statements
└── infra-permission-boundary.json   # Permission Boundary cho roles
```

## 🎯 Mục đích

- **Least Privilege**: Cấp đúng quyền cần thiết, không hơn
- **Prevent Privilege Escalation**: Ngăn team tự nâng quyền
- **Separation of Concerns**: Tách riêng services và IAM permissions

---

## 📋 Tổng quan Policies

### 1. `infra-dn-services.json`

**Mục đích**: Quyền truy cập các AWS services

| Service | Quyền | Mô tả |
|---------|-------|-------|
| **CloudFront** | Full | Quản lý CDN distributions |
| **S3** | Full | Buckets và objects |
| **EC2** | Full | Instances, Security Groups, EIP, Volumes |
| **Lambda** | Full | Functions management |
| **ECR** | Full | Container Registry |
| **CloudWatch** | Full | Logs và Metrics |
| **Route53** | Full | DNS management |
| **ACM** | Full | SSL Certificates |
| **SSM** | Full | Parameter Store, Session Manager |
| **Secrets Manager** | Full | Secrets management |
| **KMS** | Full | Encryption keys |
| **Support** | Full | AWS Support tickets |

---

### 2. `infra-dn-iam.json`

**Mục đích**: IAM permissions + Security controls

#### ✅ Allow

| Permission | Resource | Condition |
|------------|----------|-----------|
| **Tạo/Xóa IAM Roles** | `*` | Bắt buộc có `InfraPermissionBoundary` |
| **Tạo/Xóa IAM Policies** | `*` | Không giới hạn |
| **Service-Linked Roles** | `/aws-service-role/*` | Cho ECS, Auto Scaling, ELB... |
| **PassRole** | `*` | Chỉ cho EC2, ECS, Lambda |
| **Access Keys** | Chỉ chính mình | `${aws:username}` |
| **IAM Read** | `*` | List users, groups, account info |

#### ❌ Deny

| Action | Lý do |
|--------|-------|
| Tạo/Xóa IAM Users, Groups | Ngăn privilege escalation |
| Attach policies cho Users/Groups | Ngăn privilege escalation |
| Billing, Budgets, Cost Explorer | Bảo vệ thông tin tài chính |
| Organizations | Ngăn thay đổi cấu trúc org |
| Sửa/Xóa InfraPermissionBoundary | Bảo vệ security boundary |

---

### 3. `infra-permission-boundary.json`

**Mục đích**: Giới hạn quyền TỐI ĐA của roles được tạo bởi team

#### Cách hoạt động

```
Quyền thực tế của Role = Role Policy ∩ Permission Boundary
```

Dù role được attach `AdministratorAccess`, quyền thực tế vẫn bị giới hạn bởi Boundary.

#### ✅ Boundary cho phép (Workload permissions)

| Service | Actions |
|---------|---------|
| **EC2** | Describe, Get, List, CreateTags |
| **S3** | GetObject, PutObject, DeleteObject, ListBucket |
| **CloudWatch Logs** | CreateLogGroup, PutLogEvents, GetLogEvents |
| **CloudWatch Metrics** | PutMetricData, GetMetricData |
| **SSM** | GetParameter, GetParameters |
| **Secrets Manager** | GetSecretValue, DescribeSecret |
| **KMS** | Decrypt, GenerateDataKey |
| **ECR** | GetAuthorizationToken, BatchGetImage |
| **ECS** | Describe*, List* |
| **Lambda** | InvokeFunction, GetFunction |
| **SQS/SNS** | Send, Receive, Publish |
| **DynamoDB** | GetItem, PutItem, Query, Scan |
| **X-Ray** | PutTraceSegments |

#### ❌ Boundary chặn

| Action | Lý do |
|--------|-------|
| IAM (`*`) | Ngăn role tự tạo thêm roles |
| Organizations | Bảo vệ cấu trúc org |
| Billing | Bảo vệ thông tin tài chính |
| STS AssumeRole | Ngăn cross-account access |

---

## 🚀 Hướng dẫn Deploy

### Bước 1: Tạo Permission Boundary (Admin thực hiện)

```bash
aws iam create-policy \
  --policy-name InfraPermissionBoundary \
  --policy-document file://infra-permission-boundary.json \
  --description "Permission boundary for roles created by infra team"
```

### Bước 2: Tạo Services Policy (Admin thực hiện)

```bash
aws iam create-policy \
  --policy-name infra-dn-services \
  --policy-document file://infra-dn-services.json \
  --description "Services policy for Infrastructure team DN"
```

### Bước 3: Tạo IAM Policy (Admin thực hiện)

```bash
aws iam create-policy \
  --policy-name infra-dn-iam \
  --policy-document file://infra-dn-iam.json \
  --description "IAM policy for Infrastructure team DN"
```

### Bước 4: Tạo IAM Group và attach policies

```bash
# Tạo group
aws iam create-group --group-name infra-dn

# Attach policies (thay ACCOUNT_ID bằng ID thực)
aws iam attach-group-policy \
  --group-name infra-dn \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/infra-dn-services

aws iam attach-group-policy \
  --group-name infra-dn \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/infra-dn-iam
```

### Bước 5: Thêm users vào group

```bash
aws iam add-user-to-group --user-name john --group-name infra-dn
aws iam add-user-to-group --user-name nam --group-name infra-dn
```

---

## 👷 Hướng dẫn cho Team Infra DN

### Tạo IAM Role cho EC2 (Bắt buộc có Boundary)

```bash
# 1. Tạo trust policy
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# 2. Tạo role VỚI Permission Boundary (BẮT BUỘC)
aws iam create-role \
  --role-name my-ec2-role \
  --assume-role-policy-document file://trust-policy.json \
  --permissions-boundary arn:aws:iam::ACCOUNT_ID:policy/InfraPermissionBoundary

# 3. Attach policy cho role
aws iam attach-role-policy \
  --role-name my-ec2-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

> ⚠️ **Quan trọng**: Nếu không có `--permissions-boundary`, lệnh sẽ bị **ACCESS DENIED**

### Tạo Access Key cho chính mình

```bash
aws iam create-access-key
```

---

## 🛡️ Security Model

```
┌────────────────────────────────────────────────────────────────┐
│                         ADMIN                                  │
│  Quản lý: InfraPermissionBoundary, infra-dn-* policies        │
└───────────────────────────┬────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                  INFRA DN TEAM MEMBERS                         │
│  Có quyền: EC2, S3, Lambda, ECR, Route53, CloudWatch...       │
│  Tạo IAM Roles: CHỈ KHI có Permission Boundary                │
└───────────────────────────┬────────────────────────────────────┘
                            │ Tạo roles với Boundary
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                    ROLES ĐƯỢC TẠO                              │
│  Quyền bị giới hạn bởi: InfraPermissionBoundary               │
│  Chỉ có workload permissions (S3, CloudWatch, SSM, etc.)      │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔒 Privilege Escalation Prevention

| Attack Vector | Cách chặn |
|---------------|-----------|
| Tạo role với AdministratorAccess | Boundary giới hạn quyền thực tế |
| Sửa Permission Boundary | `DenyModifyPermissionBoundary` |
| Xóa Boundary khỏi Role | `DeleteRolePermissionsBoundary` bị Deny |
| Attach policy cho User/Group | `DenyIAMUserAndGroupManagement` |
| Tạo IAM User mới | `CreateUser` bị Deny |
| Cross-account AssumeRole | Boundary chặn `sts:AssumeRole` |

---

## 📝 Lưu ý quan trọng

1. **Permission Boundary phải được tạo trước** bởi Admin
2. **Không thể sửa/xóa Boundary** bởi Infra Team
3. **Mọi role phải có Boundary** mới tạo được
4. **Access Key chỉ tạo được cho chính mình**
5. **Cần attach CẢ 2 policies** (`infra-dn-services` và `infra-dn-iam`) vào group

---

## 📚 Tài liệu tham khảo

- [AWS IAM Permission Boundaries](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Service-Linked Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html)
