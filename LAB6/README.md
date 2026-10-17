# LAB 6 – LDAP/Active Directory, Captive Portal và Firewall trên pfSense

**Môn:** Thực hành An toàn hệ thống thông tin  
**Thư mục làm việc trên Windows:** `D:\LAB6`  
**Phạm vi thực hành đã chọn:** Chỉ **5 tình huống đầu**.  
**Trạng thái cập nhật:** 17/10/2026 — đang chuẩn bị MGMT và Captive Portal; **chưa thực hiện kiểm thử tình huống 1–5**.

## 1. Lưu ý quan trọng

- Thực hiện cấu hình trong **máy ảo riêng cho LAB 6**; không chỉnh sửa hoặc xóa đồ án/máy ảo gốc.
- `Ubuntu_Server` và `Nhi_Kalinux` gốc thuộc môi trường khác: **không sửa**.
- `LAB6_DC01` là bản sao Ubuntu phục vụ LAB 6; `LAB6_MGMT` là máy quản trị Kali bản sao (cần xác nhận file máy ảo đang nằm đúng thư mục).
- `nhi_pfSense` là pfSense đã được dùng cho LAB 6; **lưu ý** đây là máy có sẵn nên thay đổi trên nó có thể ảnh hưởng bài thực hành cũ.
- Không xóa các file `.vmdk`, `.vmx`, `.nvram`, `.vmsd` hoặc thư mục `.lck` khi VMware đang hoạt động.
- Không đưa mật khẩu AD, tài khoản LDAP Bind hay private key TLS vào báo cáo.

## 2. Sơ đồ địa chỉ mạng

| Vùng | VMware network | pfSense interface | IP pfSense | Thiết bị |
|---|---|---|---|---|
| WAN | VMnet8 (NAT) | em0 – WAN | 192.168.233.140/24 (DHCP tại thời điểm kiểm tra) | Truy cập Internet |
| LAN | VMnet6 | em2 – LAN | 10.6.0.1/24 | Client-A, Client-B, DC01 |
| MGMT | VMnet5 | em1 – OPT1 | 192.168.56.254/24 | LAB6_MGMT |
| DMZ | VMnet7 | em3 – OPT2 | 172.16.6.1/24 | Máy web mô phỏng (chưa hoàn tất) |

**IP các máy:**

| Máy ảo | Vai trò | Địa chỉ |
|---|---|---|
| `Nhi_Win` | Client-A – Windows 10 | 10.6.0.21/24, gateway 10.6.0.1, DNS 10.6.0.10 |
| `Windows 11_nhi` | Client-B – Windows 11 | 10.6.0.22/24, gateway 10.6.0.1, DNS 10.6.0.10 |
| `LAB6_DC01` | Samba AD Domain Controller / DNS | 10.6.0.10/24, gateway 10.6.0.1 |
| `LAB6_MGMT` | Kali quản trị pfSense | 192.168.56.10/24 trên eth0 (đã đặt tạm thời) |
| DMZ-WEB | Dịch vụ web mô phỏng | Chưa xác nhận cấu hình |

## 3. Những phần đã hoàn thành (có minh chứng trong cuộc trò chuyện)

- [x] Tạo topology 4 interface pfSense và gán IP.
- [x] Client-A ping `10.6.0.1` thành công (0% packet loss).
- [x] Client-B ping `10.6.0.1` thành công (đã xác nhận trong hội thoại).
- [x] Tạo máy `LAB6_DC01`, cấu hình mạng `ens33`, ping pfSense và Internet thành công.
- [x] Cài Samba AD, domain **LAB6.TEST**, hostname `dc01.lab6.test`.
- [x] Samba AD DC hoạt động; DNS Samba trả về `dc01.lab6.test = 10.6.0.10`.
- [x] Tạo OU `LAB6-Users` và tài khoản `sv_a`, `sv_b`.
- [x] Tạo service account `svc_pfsense_ldap` (`CN=Users,DC=lab6,DC=test`).
- [x] Kerberos `kinit` và `klist` thành công cho `sv_a@LAB6.TEST`.
- [x] Import CA `LAB6_Samba_CA` và tạo LDAP authentication server `LAB6_AD` trên pfSense.
- [x] **Diagnostics → Authentication**: `sv_a` và `sv_b` đều xác thực thành công.
- [x] pfSense Unbound cuối cùng phân giải `dc01.lab6.test` qua `127.0.0.1` thành `10.6.0.10`.
- [x] Tạo Captive Portal zone `LAB6_PORTAL` (mới ở giai đoạn cấu hình).
- [x] Xác định nguyên nhân MGMT không ping: OPT1 chưa có firewall pass rule.

## 4. Việc đang làm và các bước tiếp theo

### A. Hoàn thành đường quản trị MGMT (đang làm)

- Trên pfSense **Firewall → Rules → OPT1**, đang cấu hình rule:
  - Action **Pass**; Interface **OPT1**; IPv4; Protocol **TCP**.
  - Source **192.168.56.10/32**; Source port **Any**.
  - Destination **OPT1 address**, destination port **HTTPS 443**.
  - Description: `LAB6_ALLOW_MGMT_HTTPS`.
- **Chưa xác nhận đã Save/Apply và kiểm tra truy cập thành công.**
- Bước tiếp: Save → Apply Changes, rồi trên `LAB6_MGMT` mở `https://192.168.56.254`.
- Rule HTTPS không cho phép ICMP ping; nếu cần ping thì tạo rule ICMP riêng với nguồn giới hạn tương tự.
- IP Kali hiện được đặt **tạm thời**, có thể mất khi reboot; cần cấu hình cố định sau khi kiểm tra kết nối.

### B. Hoàn thành Captive Portal

- Zone: `LAB6_PORTAL`; chọn interface **LAN**.
- Authentication Method: **Use an Authentication backend**; Authentication Server: **LAB6_AD**.
- Secondary Authentication Server: để trống.
- Chưa xác nhận Portal được kích hoạt. **Đừng kích hoạt trên LAN trước khi kiểm tra đường MGMT**, tránh mất WebGUI đang mở từ Client-A.
- Cần cấu hình **HTTPS login với chứng chỉ phù hợp** để tránh gửi mật khẩu user qua HTTP.
- Sau đó kiểm tra đăng nhập `sv_a`, `sv_b`; chụp minh chứng.

### C. Chuẩn bị DMZ-WEB và quy tắc Firewall

- Dựng web mô phỏng cho các đích thuộc DMZ, thiết lập IP, thử truy cập trước khi áp rule chặn.
- Tạo Alias, Schedule, rule, kiểm thử và lưu ảnh minh chứng.
- Kiểm tra Firewall Log và State Table sau khi thay đổi rule; tạo kết nối mới hoặc reset state có chọn lọc khi cần.

## 5. Năm tình huống cần làm

| Số | Nội dung | Địa chỉ ví dụ theo phạm vi đã trao đổi | Trạng thái |
|---|---|---|---|
| 1/5 | Chặn Client-A truy cập JOB_SITE | JOB_SITE: `172.16.6.20` | Chưa làm |
| 2/5 | Chặn Client-A và Client-B truy cập RESTRICTED_SITE | `172.16.6.40` | Chưa làm |
| 3/5 | Chỉ cho Client-B truy cập SOCIAL_SITE trong giờ nghỉ được quy định | `172.16.6.30` | Chưa làm |
| 4/5 | Giới hạn HTTP/HTTPS theo giờ hành chính | Theo schedule của bài | Chưa làm |
| 5/5 | Cô lập DMZ khỏi LAN; cho phép LAN truy cập các web được phép | Theo rule hai chiều | Chưa làm |

**Quy tắc trình bày tiến độ:** Khi bắt đầu kiểm thử mỗi tình huống, ghi rõ `TÌNH HUỐNG X/5`, mục tiêu, firewall rule, cách kiểm thử, kết quả và ảnh minh chứng. Không mặc định tình huống đã xong nếu chưa có kiểm thử.

## 6. Yêu cầu nộp bài (theo phần người dùng đã gửi)

- Nộp báo cáo cá nhân theo mẫu tên: `[Mã lớp]-Lab6_MSSV-TenSV.docx`.
- Ảnh phải chụp trực tiếp trên máy, có IP/rule liên quan.
- Cần minh chứng topology 4 adapter, LDAP Test `sv_a` và `sv_b`, Captive Portal login, Alias, Schedule, mỗi tình huống tối thiểu 1 ảnh rule + 1 ảnh test, Firewall Log, State Table.
- Điền bảng kết quả và trả lời 12 câu hỏi lý thuyết.
- Xuất **Diagnostics → Backup & Restore → Download configuration** để nộp `config.xml`.
- Ghi chú: Tài liệu gốc yêu cầu minh chứng topology VirtualBox; môi trường thực tế đang dùng VMware. Cần xác nhận giảng viên chấp nhận minh chứng VMware.

## 7. Cấu hình và bảo mật cần ghi nhớ

- Samba realm: `LAB6.TEST`; Domain: `LAB6`; DC: `dc01.lab6.test`; DNS: `10.6.0.10`.
- LDAP server pfSense: `LAB6_AD`, hostname `dc01.lab6.test`, TCP 389, **STARTTLS Encrypted**, CA `LAB6_Samba_CA`.
- Base DN: `DC=lab6,DC=test`; Search scope: **Entire Subtree**; container user: `OU=LAB6-Users`; User naming: `sAMAccountName`.
- Bind DN: `CN=svc_pfsense_ldap,CN=Users,DC=lab6,DC=test` (không ghi mật khẩu vào README).
- Có cảnh báo pfSense admin đang dùng mật khẩu mặc định: **cần đổi mật khẩu** khi phù hợp, và lưu an toàn.
- Custom Options Unbound đã được thử cho vùng `test.`; cần sao lưu cấu hình hoạt động trước khi chỉnh tiếp. DNS cuối cùng đã được xác minh bằng `drill @127.0.0.1 dc01.lab6.test`.

---

**Điểm tiếp tục ngay:** Hoàn tất rule `LAB6_ALLOW_MGMT_HTTPS` trên pfSense OPT1, thử mở `https://192.168.56.254` từ máy `LAB6_MGMT`. Sau đó cấu hình HTTPS Captive Portal, mới chuyển sang 5 tình huống Firewall.
