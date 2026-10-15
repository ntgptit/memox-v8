---
id: BR-TOPIK-027
title: Đổi tài khoản xoá dữ liệu TOPIK cục bộ
status: active
summary: Đăng xuất hay đổi tài khoản xoá mọi lượt TOPIK cục bộ; tài khoản mới nhận lại lượt đã nộp của nó qua đồng bộ; lượt dở bị mất.
superseded_by:
---
## Rule

Dữ liệu TOPIK MUST nằm trong lần xoá dữ liệu cục bộ khi đổi tài khoản, đăng xuất hay xoá tài khoản (`LocalDataReset`). Tài khoản mới nhận lượt đã nộp của chính nó qua pull. Lượt dở của tài khoản cũ bị mất, như phiên học đang dở.

**Enforced by:** store
**Liên quan:** BR-TOPIK-026

## Lý do

Dữ liệu học theo tài khoản; để lại lượt của tài khoản cũ sẽ làm lộ nó cho tài khoản sau trên cùng máy.

## Ví dụ

Đăng xuất khi có hai lượt đã nộp và một lượt dở: sau đăng xuất, máy không còn lượt nào; đăng nhập lại thì hai lượt đã nộp quay về.

## Edge case

Màn TOPIK đang mở khi tài khoản đổi: màn hiện trạng thái lượt hoặc đề không còn.
