# Bài 3: Tách biệt luồng CI/CD đa môi trường (Staging & Production) với GitHub Environments

## 1. Mục tiêu
- **Quản lý hạ tầng triển khai đa môi trường**: Tách bạch môi trường thử nghiệm (**Staging**) và môi trường thực tế (**Production**) thông qua tính năng **GitHub Environments**.
- **Kiểm soát chất lượng và an toàn triển khai (Environment Protection Rules)**: Cấu hình quy tắc bảo vệ môi trường Production với **Required reviewers**, bắt buộc phê duyệt thủ công (Manual Approval) trước khi mã nguồn được deploy lên Production.

---

## 2. Cấu trúc thư mục nộp bài
```text
homework/session_12/ex3/
├── .github/
│   └── workflows/
│       └── cd-multi-env.yml    # File kịch bản luồng CD đa môi trường
└── README.md                   # Báo cáo chi tiết và hướng dẫn kiểm thử
```

---

## 3. Cấu hình GitHub Environments trên Repository

Trên GitHub Repository (`DoKhacQuyen94/IT209_Session12_HW_baitap03`):
Truy cập vào **Settings** ➔ **Environments**:

1. **Môi trường `staging`**:
   - Nhấn **New environment** ➔ Nhập tên `staging`.
   - Không cấu hình Protection rules (cho phép tự động triển khai liên tục).
   - URL môi trường: `https://api.staging.example.com`.

2. **Môi trường `production`**:
   - Nhấn **New environment** ➔ Nhập tên `production`.
   - Bật tùy chọn **Required reviewers**.
   - Thêm tài khoản người duyệt: `@DoKhacQuyen94`.
   - URL môi trường: `https://api.prod.example.com`.

---

## 4. Kịch bản Workflow `.github/workflows/cd-multi-env.yml`

```yaml
name: Multi-Environment CD Pipeline

on:
  push:
    branches:
      - main
      - develop
  workflow_dispatch:

jobs:
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://api.staging.example.com
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Deploy to Staging Environment
        run: |
          echo "=========================================="
          echo "Deploying application to STAGING environment..."
          echo "Target Environment: staging"
          echo "Target URL: https://api.staging.example.com"
          echo "Branch: ${{ github.ref_name }}"
          echo "Commit SHA: ${{ github.sha }}"
          echo "Deployed By: ${{ github.actor }}"
          echo "Status: SUCCESS"
          echo "=========================================="

  deploy-prod:
    name: Deploy to Production
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://api.prod.example.com
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Deploy to Production Environment
        run: |
          echo "=========================================="
          echo "Deploying application to PRODUCTION environment..."
          echo "Target Environment: production"
          echo "Target URL: https://api.prod.example.com"
          echo "Branch: ${{ github.ref_name }}"
          echo "Commit SHA: ${{ github.sha }}"
          echo "Approved and Triggered By: ${{ github.actor }}"
          echo "Status: PRODUCTION DEPLOYMENT SUCCESSFUL"
          echo "=========================================="
```

---

## 5. Quy trình kiểm thử và kết quả

### 5.1. Kiểm thử nhánh `develop` (Staging)
1. Thực hiện push code lên nhánh `develop`:
   ```bash
   git checkout -b develop
   git push -u origin develop
   ```
2. **Kết quả**:
   - Workflow được kích hoạt.
   - Job `deploy-staging` chạy tự động không cần phê duyệt và hoàn thành thành công (tích xanh).
   - Job `deploy-prod` bị bỏ qua (Skipped) do điều kiện nhánh `github.ref == 'refs/heads/main'` không thỏa mãn.

### 5.2. Kiểm thử nhánh `main` (Production - Chờ phê duyệt)
1. Thực hiện push code lên nhánh `main`:
   ```bash
   git checkout main
   git push -u origin main
   ```
2. **Hiện tượng quan sát được**:
   - Workflow được kích hoạt.
   - Job `deploy-staging` bị bỏ qua (Skipped).
   - Job `deploy-prod` chuyển sang trạng thái màu vàng: **Waiting for review** (Chờ phê duyệt từ reviewer `@DoKhacQuyen94`).
   - Xuất hiện nút **Review deployments**.
3. **Thao tác phê duyệt (Approval)**:
   - Nhấn nút **Review deployments**.
   - Tích chọn môi trường **production**.
   - (Tùy chọn) Nhập lý do: *"Approved release for production"*.
   - Nhấn **Approve and deploy**.
4. **Kết quả sau phê duyệt**:
   - Runner lập tức được cấp phát và thực thi Job `deploy-prod`.
   - Toàn bộ Job hoàn tất với trạng thái tích xanh (**Success**).
   - URL triển khai hiển thị liên kết trực tiếp tới `https://api.prod.example.com`.
