# Danh mục thực thi kịch bản IT cho AI agent

| | |
|---|---|
| **Status** | đang áp dụng |
| **Purpose** | Lập chỉ mục từng kịch bản cùng mức sẵn sàng, hồ sơ thực thi, chuẩn bị, dọn dẹp và truy vết để agent chọn phép kiểm thử mà không suy đoán |
| **Scope** | Toàn bộ kịch bản IT hiện có trong `docs/it-scenarios`; không lặp lại các bước thao tác |
| **Source of truth for** | Mức sẵn sàng, hồ sơ thực thi, chuẩn bị, dọn dẹp và truy vết theo từng ID kịch bản IT |
| **Depends on** | `README.md`, `00-agent-execution-guide.md`, mười một tệp kịch bản theo nhóm chức năng |
| **Updated by** | `docs/superpowers/plans/2026-09-23-docs-v8-reset.md` — V8 reset: gỡ trích dẫn AD và task ID V7 khỏi cột truy vết |
| **Last updated** | 2026-09-23 |

Agent MUST tìm ID ở danh mục này trước khi chạy. **Cột `Profile` quyết định lệnh chạy**: `HOST-FLOW` và `HOST-WIDGET` chạy bằng `flutter test`, chỉ `DEVICE-E2E` cần emulator hoặc thiết bị. Bảng phân loại từng kịch bản theo hồ sơ thực thi kèm lý do nằm ở [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md). Cột tệp chỉ tới tài liệu chứa
các bước gốc. Ý nghĩa mức sẵn sàng, hồ sơ thực thi, chuẩn bị và dọn dẹp nằm trong
[`00-agent-execution-guide.md`](00-agent-execution-guide.md).

## Điều hướng và tiếp tục

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-NAV-001 | `01-navigation-and-continuity.md` | READY | `HOST-WIDGET` | — | SETUP-EMPTY | CLEAN-RESET | UC-DECK-003 |
| IT-NAV-002 | `01-navigation-and-continuity.md` | READY | `HOST-WIDGET` | — | SETUP-TREE-UNSET | CLEAN-RESET | BR-STUDY-020 |
| IT-NAV-003 | `01-navigation-and-continuity.md` | READY | `HOST-WIDGET` | — | SETUP-TREE-CARD | CLEAN-RESET | UC-DECK-003 |
| IT-NAV-004 | `01-navigation-and-continuity.md` | READY | `HOST-WIDGET` | — | SETUP-TREE-CARD | CLEAN-RESET | UC-DECK-003 |
| IT-NAV-005 | `01-navigation-and-continuity.md` | READY | `HOST-WIDGET` | IT-PLAT-004 | SETUP-EMPTY | CLEAN-RESET | — |
| IT-NAV-006 | `01-navigation-and-continuity.md` | READY | `HOST-FLOW` | IT-PLAT-002 | SETUP-EMPTY | CLEAN-RESET | UC-DECK-001, UC-DECK-002, UC-CARD-001, UC-DECK-004 |
| IT-NAV-007 | `01-navigation-and-continuity.md` | READY | `DEVICE-E2E` | — | SETUP-TREE-CARD | CLEAN-RESET | — |
| IT-NAV-008 | `01-navigation-and-continuity.md` | READY | `HOST-WIDGET` | — | SETUP-STUDY-SCOPE | CLEAN-RESET | UC-STUDY-001, BR-STUDY-020 |
| IT-NAV-009 | `01-navigation-and-continuity.md` | READY | `HOST-WIDGET` | — | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | UC-STUDY-001, BR-STUDY-020, BR-STUDY-055 |
| IT-NAV-010 | `01-navigation-and-continuity.md` | READY | `HOST-WIDGET` | IT-PLAT-005 | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-STUDY-001 A3, BR-STUDY-014 |
| IT-NAV-011 | `01-navigation-and-continuity.md` | READY | `HOST-WIDGET` | — | SETUP-EMPTY | CLEAN-RESET | UC-PROGRESS-001, BR-PROGRESS-009 |
| IT-NAV-012 | `01-navigation-and-continuity.md` | READY | `HOST-WIDGET` | — | SETUP-CARD-BASIC | CLEAN-RESET | UC-TRANSFER-001, BR-TRANSFER-008 |

## Vòng đời bộ thẻ gốc

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-DECK-001 | `02-root-deck-lifecycle.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-DECK-001F | SETUP-EMPTY | CLEAN-RESET | UC-DECK-001, BR-SRS-001 |
| IT-DECK-002 | `02-root-deck-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-D-SM2 | CLEAN-RESET | UC-DECK-001, BR-DECK-021 |
| IT-DECK-003 | `02-root-deck-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-EMPTY | CLEAN-RESET | UC-DECK-001, BR-DECK-020, BR-SRS-001 |
| IT-DECK-004 | `02-root-deck-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-EMPTY | CLEAN-RESET | UC-DECK-001, BR-DECK-020 |
| IT-DECK-005 | `02-root-deck-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-EMPTY | CLEAN-RESET | UC-DECK-001 A1 |
| IT-DECK-006 | `02-root-deck-lifecycle.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-DECK-006F | SETUP-D-EB | CLEAN-RESET | UC-DECK-002, BR-DECK-020 |
| IT-DECK-007 | `02-root-deck-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-TREE-CARD | CLEAN-RESET | UC-DECK-002 A4, BR-DECK-023 |
| IT-DECK-008 | `02-root-deck-lifecycle.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-DECK-008F | SETUP-TREE-CARD | CLEAN-RESET | UC-DECK-002, BR-DECK-022, BR-DECK-023 |

## Cây bộ thẻ và loại nội dung

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-TREE-001 | `03-deck-tree-and-content-type.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-TREE-001F | SETUP-D-EB | CLEAN-RESET | UC-DECK-004, BR-DECK-004, BR-DECK-005 |
| IT-TREE-002 | `03-deck-tree-and-content-type.md` | READY | `HOST-WIDGET` | — | SETUP-TREE-UNSET | CLEAN-RESET | UC-DECK-004, BR-DECK-006, BR-DECK-007 |
| IT-TREE-003 | `03-deck-tree-and-content-type.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-TREE-003F | SETUP-TREE-UNSET | CLEAN-RESET | UC-DECK-004, BR-DECK-008, BR-DECK-009 |
| IT-TREE-004 | `03-deck-tree-and-content-type.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-TREE-004F | SETUP-UNSET-CHILD:Grammar | CLEAN-RESET | UC-DECK-004, BR-DECK-008, BR-DECK-010 |
| IT-TREE-005 | `03-deck-tree-and-content-type.md` | READY | `HOST-FLOW` | — | SETUP-UNSET-CHILD:Unclassified | CLEAN-RESET | UC-DECK-004 E1, BR-DECK-008 |
| IT-TREE-006 | `03-deck-tree-and-content-type.md` | READY | `HOST-FLOW` | — | SETUP-DECK-TYPED-WITH-CHILD | CLEAN-RESET | UC-DECK-004 A3, BR-DECK-015 |
| IT-TREE-007 | `03-deck-tree-and-content-type.md` | READY | `HOST-FLOW` | — | SETUP-TREE-UNSET | CLEAN-RESET | UC-DECK-005, BR-DECK-015 |
| IT-TREE-008 | `03-deck-tree-and-content-type.md` | READY | `HOST-FLOW` | — | SETUP-TREE-UNSET | CLEAN-RESET | UC-DECK-004 A3, BR-DECK-015 |
| IT-TREE-009 | `03-deck-tree-and-content-type.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-TREE-009F | SETUP-MOVE-TREE | CLEAN-RESET | UC-DECK-005, BR-DECK-018 |
| IT-TREE-010 | `03-deck-tree-and-content-type.md` | READY | `HOST-FLOW` | — | SETUP-CYCLE-TREE | CLEAN-RESET | UC-DECK-005 E1, BR-DECK-016, BR-DECK-017 |
| IT-TREE-011 | `03-deck-tree-and-content-type.md` | READY | `HOST-FLOW` | — | SETUP-MOVE-TREE | CLEAN-RESET | UC-DECK-005 E2, BR-DECK-010 |
| IT-TREE-012 | `03-deck-tree-and-content-type.md` | READY | `HOST-FLOW` | — | SETUP-CROSS-SCHEDULER-MOVE | CLEAN-RESET | UC-DECK-005 E3, BR-SRS-005, BR-SRS-006 |
| IT-TREE-013 | `03-deck-tree-and-content-type.md` | READY | `HOST-FLOW` | — | SETUP-DEEP-10 | CLEAN-RESET | UC-DECK-004 E4, UC-DECK-005 E5, BR-DECK-001 |
| IT-TREE-014 | `03-deck-tree-and-content-type.md` | READY | `HOST-FLOW` | — | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-CARD-001 A2, BR-DECK-015 |

## Khám phá bộ thẻ và tiến độ

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-DISC-001 | `04-deck-discovery-and-progress.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-DISC-001F | S-DUE | CLEAN-RESET | UC-DECK-003, BR-STUDY-051, BR-STUDY-046 |
| IT-DISC-002 | `04-deck-discovery-and-progress.md` | READY | `HOST-WIDGET` | — | S-DUE | CLEAN-RESET | UC-DECK-003 A1, BR-STUDY-008 |
| IT-DISC-003 | `04-deck-discovery-and-progress.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-DISC-003F | S-DUE | CLEAN-RESET | UC-DECK-003, BR-STUDY-051, BR-STUDY-046 |
| IT-DISC-004 | `04-deck-discovery-and-progress.md` | READY | `HOST-WIDGET` | — | S-DUE | CLEAN-RESET | UC-DECK-003, BR-STUDY-008 |
| IT-DISC-005 | `04-deck-discovery-and-progress.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-DISC-005F | SETUP-ROOT-TRIO | CLEAN-RESET | UC-DECK-003 |
| IT-DISC-006 | `04-deck-discovery-and-progress.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-DISC-006F | SETUP-SEARCH-TREES | CLEAN-RESET | UC-DECK-003 A3, BR-DECK-002, BR-DECK-003 |
| IT-DISC-007 | `04-deck-discovery-and-progress.md` | READY | `HOST-WIDGET` | — | SETUP-D-EB | CLEAN-RESET | UC-DECK-003 |
| IT-DISC-008 | `04-deck-discovery-and-progress.md` | READY | `HOST-WIDGET` | — | SETUP-TREE-CARD | CLEAN-RESET | UC-DECK-003 A2, BR-STUDY-001 |

## Vòng đời thẻ

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-CARD-001 | `05-card-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-CARD-001 A3 |
| IT-CARD-002 | `05-card-lifecycle.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-CARD-002F | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-CARD-001, BR-CARD-001, BR-CARD-004 |
| IT-CARD-003 | `05-card-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-CARD-001 E1, BR-CARD-001 |
| IT-CARD-004 | `05-card-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-CARD-001, BR-CARD-002 |
| IT-CARD-005 | `05-card-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-CARD-001, BR-CARD-003 |
| IT-CARD-006 | `05-card-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | BR-CARD-003 |
| IT-CARD-007 | `05-card-lifecycle.md` | READY | `HOST-WIDGET` | — | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-CARD-001 A4 |
| IT-CARD-008 | `05-card-lifecycle.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-CARD-008F | SETUP-CARD-BASIC | CLEAN-RESET | UC-CARD-001 A1, BR-CARD-005 |
| IT-CARD-009 | `05-card-lifecycle.md` | READY | `HOST-FLOW` | — | S-PROGRESS | CLEAN-RESET | UC-CARD-001 A1, BR-CARD-005, BR-CARD-009 |
| IT-CARD-010 | `05-card-lifecycle.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-CARD-010F | SETUP-CARD-BASIC | CLEAN-RESET | UC-CARD-001 A2 |
| IT-CARD-011 | `05-card-lifecycle.md` | READY | `HOST-FLOW` | — | SETUP-CARD-SINGLE | CLEAN-RESET | UC-CARD-001 A2, BR-DECK-015 |
| IT-CARD-012 | `05-card-lifecycle.md` | READY | `HOST-FLOW` | — | SETUP-CARD-SINGLE | CLEAN-RESET | UC-CARD-001 A5, BR-DECK-015, BR-CARD-010 |
| IT-CARD-013 | `05-card-lifecycle.md` | READY | `HOST-FLOW` | — | SETUP-TREE-CARD | CLEAN-RESET | UC-CARD-001 E5, BR-CARD-010 |
| IT-CARD-014 | `05-card-lifecycle.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | — | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-TRANSFER-001, BR-TRANSFER-002, BR-TRANSFER-004, BR-TRANSFER-005 |
| IT-CARD-015 | `05-card-lifecycle.md` | READY | `HOST-FLOW` | — | SETUP-CARD-BASIC | CLEAN-RESET | UC-TRANSFER-001 E4, UC-TRANSFER-001 E5, BR-TRANSFER-001, BR-TRANSFER-003, BR-TRANSFER-004 |

## Khám phá và tổ chức thẻ

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-ORG-001 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-ORG-001F | SETUP-CARD-BASIC | CLEAN-RESET | UC-CARD-001, S1 |
| IT-ORG-002 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` | — | SETUP-CARD-BASIC | CLEAN-RESET | UC-CARD-001, S1 |
| IT-ORG-003 | `06-card-discovery-and-organization.md` | READY | `HOST-FLOW` | — | S-DUE | CLEAN-RESET | UC-CARD-001, BR-STUDY-051, BR-STUDY-047 |
| IT-ORG-004 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-ORG-004F | SETUP-CARD-PLAIN | CLEAN-RESET | BR-CARD-009 |
| IT-ORG-005 | `06-card-discovery-and-organization.md` | READY | `HOST-FLOW` | — | S-DUE | CLEAN-RESET | BR-CARD-007, BR-CARD-009, BR-STUDY-051, BR-STUDY-047 |
| IT-ORG-006 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` | — | SETUP-TREE-CARD | CLEAN-RESET | BR-CARD-009 |
| IT-ORG-007 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-ORG-007F | SETUP-CARD-PLAIN | CLEAN-RESET | BR-TAG-001 |
| IT-ORG-008 | `06-card-discovery-and-organization.md` | READY | `HOST-FLOW` | — | SETUP-CARD-TAGS | CLEAN-RESET | BR-TAG-001 |
| IT-ORG-009 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` | — | SETUP-CARD-SINGLE | CLEAN-RESET | BR-TAG-001, BR-TAG-002 |
| IT-ORG-010 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-ORG-010F | S-PROGRESS | CLEAN-RESET | BR-CARD-006, BR-CARD-007, BR-CARD-008 |
| IT-ORG-011 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` | — | SETUP-TREE-CARD | CLEAN-RESET | UC-CARD-001, UC-DECK-003 |
| IT-ORG-012 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` | — | S-LARGE | CLEAN-RESET | — |
| IT-ORG-013 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` | — | S-LARGE | CLEAN-RESET | UC-CARD-001 A6, BR-CARD-012 |
| IT-ORG-014 | `06-card-discovery-and-organization.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | — | SETUP-CARD-BASIC | CLEAN-RESET | UC-CARD-001 A6, UC-CARD-001 E6, BR-CARD-011 |

## Điểm vào chức năng học và tùy chọn

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-STUDY-001 | `07-study-entry-and-options.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-STUDY-001F | S-STUDY-MIXED-EB-V2 | CLEAN-RESET | UC-STUDY-001, BR-STUDY-051, BR-STUDY-046, BR-STUDY-047 |
| IT-STUDY-002 | `07-study-entry-and-options.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-STUDY-001, BR-STUDY-020 |
| IT-STUDY-003 | `07-study-entry-and-options.md` | READY | `HOST-FLOW` | — | S-STUDY-FUTURE-EB-V2 | CLEAN-RESET | UC-STUDY-001 E1, BR-STUDY-008, BR-STUDY-054 |
| IT-STUDY-004 | `07-study-entry-and-options.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-STUDY-004F | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | UC-STUDY-001, BR-MODE-009, BR-STUDY-055, BR-STUDY-044 |
| IT-STUDY-005 | `07-study-entry-and-options.md` | READY | `HOST-FLOW` | — | S-STUDY-REVIEW-SM2-V2 | CLEAN-RESET | UC-STUDY-001, BR-STUDY-009, BR-STUDY-055 |
| IT-STUDY-006 | `07-study-entry-and-options.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-STUDY-006F | S-STUDY-REVIEW-EB-MINIMAL-V2 | CLEAN-RESET | UC-STUDY-001, BR-MODE-009, BR-MODE-010, BR-STUDY-037, BR-STUDY-045 |
| IT-STUDY-007 | `07-study-entry-and-options.md` | READY | `HOST-FLOW` | — | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | UC-STUDY-001, BR-STUDY-071, BR-STUDY-044 |
| IT-STUDY-008 | `07-study-entry-and-options.md` | READY | `HOST-FLOW` | IT-PLAT-002 | SETUP-STUDY-EB-21 | CLEAN-RESET | BR-STUDY-056, BR-STUDY-057 |
| IT-STUDY-009 | `07-study-entry-and-options.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-21 | CLEAN-RESET | BR-DECK-025, BR-STUDY-024, BR-STUDY-056 |
| IT-STUDY-010 | `07-study-entry-and-options.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-21 | CLEAN-RESET | BR-STUDY-003, BR-STUDY-024 |
| IT-STUDY-011 | `07-study-entry-and-options.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-SCOPE | CLEAN-RESET | UC-STUDY-001, BR-STUDY-002, BR-STUDY-051 |
| IT-STUDY-012 | `07-study-entry-and-options.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-21 | CLEAN-RESET | BR-STUDY-021, BR-STUDY-024, BR-STUDY-057 |
| IT-STUDY-013 | `07-study-entry-and-options.md` | READY | `HOST-FLOW` | — | S-STUDY-BROKEN-OPTIONS-V2 | CLEAN-RESET | BR-STUDY-003, BR-STUDY-056, BR-STUDY-057 |

## Phiên học thẻ mới

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-LEARN-001 | `08-study-learning-session.md` | READY | `HOST-FLOW` + `HOST-WIDGET` | IT-LEARN-001W | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-STUDY-001, BR-MODE-007, BR-MODE-002, BR-MODE-003, BR-MODE-004 |
| IT-LEARN-002 | `08-study-learning-session.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-SM2-4 | CLEAN-RESET | UC-STUDY-001, BR-MODE-003, BR-MODE-004 |
| IT-LEARN-003 | `08-study-learning-session.md` | READY | `HOST-WIDGET` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-MODE-005, BR-MODE-006 |
| IT-LEARN-004 | `08-study-learning-session.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-STUDY-021, BR-STUDY-022, BR-STUDY-061, BR-STUDY-043 |
| IT-LEARN-005 | `08-study-learning-session.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-PLAIN | CLEAN-RESET | UC-STUDY-001 A0b, BR-STUDY-071, BR-STUDY-025, BR-STUDY-053 |
| IT-LEARN-006 | `08-study-learning-session.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-4 | CLEAN-RESET | BR-MODE-009, BR-STUDY-037, BR-STUDY-040, BR-STUDY-025 |
| IT-LEARN-007 | `08-study-learning-session.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-1 | CLEAN-RESET | BR-MODE-009, BR-STUDY-045 |
| IT-LEARN-008 | `08-study-learning-session.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-STUDY-059, BR-STUDY-060, BR-STUDY-069 |
| IT-LEARN-009 | `08-study-learning-session.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-SM2-4 | CLEAN-RESET | UC-STUDY-001 A2b, BR-STUDY-005, BR-STUDY-007, BR-CARD-009, BR-STUDY-073 |
| IT-LEARN-010 | `08-study-learning-session.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-SRS-003, BR-STUDY-006, BR-STUDY-074, BR-STUDY-053, BR-STUDY-054, BR-STUDY-058 |
| IT-LEARN-011 | `08-study-learning-session.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-21 | CLEAN-RESET | BR-STUDY-003, BR-STUDY-024 |
| IT-LEARN-012 | `08-study-learning-session.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-STUDY-001 A3, BR-STUDY-014, BR-STUDY-019, BR-STUDY-053 |

## Phiên ôn tập

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-REVIEW-001 | `09-study-review-session.md` | READY | `HOST-FLOW` | — | S-STUDY-MIXED-EB-V2 | CLEAN-RESET | UC-STUDY-001, BR-STUDY-051 |
| IT-REVIEW-002 | `09-study-review-session.md` | READY | `HOST-FLOW` + `HOST-WIDGET` | IT-REVIEW-002W | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-MODE-003, BR-STUDY-055 |
| IT-REVIEW-003 | `09-study-review-session.md` | READY | `HOST-WIDGET` | — | S-STUDY-REVIEW-SM2-V2 | CLEAN-RESET | BR-STUDY-009, BR-MODE-011, BR-STUDY-055 |
| IT-REVIEW-004 | `09-study-review-session.md` | READY | `HOST-FLOW` | — | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-STUDY-002, BR-STUDY-003, BR-STUDY-021, BR-STUDY-024 |
| IT-REVIEW-005 | `09-study-review-session.md` | READY | `HOST-FLOW` | — | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-SRS-018, BR-SRS-019, BR-SRS-014, BR-SRS-015, BR-SRS-016, BR-SRS-017, BR-STUDY-023, BR-STUDY-052 |
| IT-REVIEW-006 | `09-study-review-session.md` | READY | `HOST-FLOW` | — | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-SRS-008, BR-SRS-009, BR-STUDY-074 |
| IT-REVIEW-007 | `09-study-review-session.md` | READY | `HOST-FLOW` | — | S-STUDY-REVIEW-SM2-V2 | CLEAN-RESET | BR-SRS-010, BR-SRS-011, BR-SRS-012, BR-STUDY-074 |
| IT-REVIEW-008 | `09-study-review-session.md` | READY | `HOST-FLOW` | — | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-STUDY-074, BR-STUDY-054 |
| IT-REVIEW-009 | `09-study-review-session.md` | READY | `HOST-FLOW` | — | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | UC-STUDY-001 A4, BR-STUDY-003 |
| IT-REVIEW-010 | `09-study-review-session.md` | READY | `HOST-FLOW` | — | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-MODE-009, BR-STUDY-071, BR-STUDY-044 |

## Các chế độ học

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-MODE-001 | `10-study-modes.md` | READY | `HOST-WIDGET` | — | S-STUDY-MIXED-EB-V2 | CLEAN-RESET | UC-STUDY-001, BR-MODE-008, BR-STUDY-051 |
| IT-MODE-002 | `10-study-modes.md` | READY | `HOST-WIDGET` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-MODE-005, BR-MODE-006 |
| IT-MODE-003 | `10-study-modes.md` | READY | `HOST-WIDGET` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-STUDY-059 |
| IT-MODE-004 | `10-study-modes.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-MODE-004F | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-MODE-012, BR-STUDY-060, BR-STUDY-062, BR-STUDY-070 |
| IT-MODE-005 | `10-study-modes.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-MODE-005F | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-STUDY-037, BR-STUDY-041, BR-STUDY-042 |
| IT-MODE-006 | `10-study-modes.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-4 | CLEAN-RESET | BR-MODE-009, BR-STUDY-037, BR-STUDY-040 |
| IT-MODE-007 | `10-study-modes.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-STUDY-061, BR-STUDY-043 |
| IT-MODE-008 | `10-study-modes.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-MODE-008F | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-STUDY-031, BR-STUDY-032 |
| IT-MODE-009 | `10-study-modes.md` | READY | `HOST-WIDGET` + `HOST-FLOW` | IT-MODE-009F | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-STUDY-031, BR-STUDY-033, BR-STUDY-034, BR-STUDY-036 |
| IT-MODE-010 | `10-study-modes.md` | READY | `HOST-FLOW` | — | S-STUDY-FILL-V2 | CLEAN-RESET | BR-STUDY-026, BR-STUDY-029, BR-STUDY-030 |
| IT-MODE-011 | `10-study-modes.md` | READY | `HOST-FLOW` | — | S-STUDY-FILL-V2 | CLEAN-RESET | BR-STUDY-027, BR-STUDY-028, BR-STUDY-029, BR-STUDY-030 |
| IT-MODE-012 | `10-study-modes.md` | READY | `HOST-WIDGET` | — | SETUP-STUDY-ALL-MODES | CLEAN-RESET | BR-STUDY-009, BR-MODE-011, BR-MODE-006, BR-STUDY-055 |
| IT-MODE-013 | `10-study-modes.md` | READY | `HOST-WIDGET` | — | SETUP-STUDY-ALL-MODES | CLEAN-RESET | — |
| IT-MODE-014 | `10-study-modes.md` | READY | `HOST-FLOW` | — | S-STUDY-GUESS-BLOCKED-V2 | CLEAN-RESET | BR-STUDY-037, BR-STUDY-040 |
| IT-MODE-015 | `10-study-modes.md` | READY | `HOST-FLOW` | — | S-STUDY-GUESS-SOURCE-V2 | CLEAN-RESET | BR-STUDY-037, BR-STUDY-038, BR-STUDY-039 |

## Tiếp tục phiên học và lỗi

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-CONT-001 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` | IT-PLAT-003 | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-STUDY-001 A3b, BR-STUDY-010, BR-STUDY-021, BR-STUDY-072 |
| IT-CONT-002 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-STUDY-014, BR-STUDY-072 |
| IT-CONT-003 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-STUDY-001 A3b, BR-STUDY-011, BR-STUDY-019, BR-STUDY-072 |
| IT-CONT-004 | `11-study-continuity-and-failures.md` | READY | `HOST-WIDGET` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-STUDY-001 A3, BR-STUDY-014, BR-STUDY-019 |
| IT-CONT-005 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-STUDY-013 |
| IT-CONT-006 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` | — | S-STUDY-RESUME-V2 | CLEAN-RESET | BR-STUDY-021, BR-STUDY-024 |
| IT-CONT-007 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` + `HOST-WIDGET` | IT-CONT-007W | S-STUDY-RESUME-V2 | CLEAN-RESET | UC-STUDY-001 A5 |
| IT-CONT-008 | `11-study-continuity-and-failures.md` | READY | `DEVICE-E2E` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-STUDY-001 |
| IT-CONT-009 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` | — | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-SRS-001, BR-STUDY-015, BR-STUDY-050 |
| IT-CONT-010 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` | — | S-STUDY-RESUME-V2 | CLEAN-RESET | UC-STUDY-001 E4, BR-SRS-026, BR-STUDY-017 |
| IT-CONT-011 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` | — | S-STUDY-FAILURE-V2 | CLEAN-RESET | UC-STUDY-001 E2, BR-STUDY-004 |
| IT-CONT-012 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` | — | S-STUDY-FAILURE-V2 | CLEAN-RESET | UC-STUDY-001 E3, BR-STUDY-018, BR-STUDY-019 |
| IT-CONT-013 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` + `HOST-WIDGET` | IT-CONT-013W | S-STUDY-FAILURE-V2 | CLEAN-RESET | UC-STUDY-001 E5 |
| IT-CONT-014 | `11-study-continuity-and-failures.md` | READY | `HOST-FLOW` | — | S-STUDY-MIXED-EB-V2 | CLEAN-RESET | UC-STUDY-001, BR-STUDY-014, BR-STUDY-072 |

## Ranh giới nền tảng

| ID | Tệp | Mức sẵn sàng | Profile | Dẫn xuất | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|---|
| IT-PLAT-001 | `13-platform-boundaries.md` | READY | `DEVICE-E2E` | IT-NAV-001 | SETUP-EMPTY | CLEAN-RESET | UC-DECK-003 |
| IT-PLAT-002 | `13-platform-boundaries.md` | READY | `DEVICE-E2E` | IT-NAV-006 · IT-DECK-001 · IT-CARD-002 · IT-CARD-008 · IT-CARD-010 · IT-ORG-004 · IT-STUDY-008 | SETUP-EMPTY | CLEAN-RESET | UC-DECK-001, UC-CARD-001 |
| IT-PLAT-003 | `13-platform-boundaries.md` | READY | `DEVICE-E2E` | IT-CONT-001 | SETUP-EMPTY | CLEAN-RESET | UC-STUDY-001 A3b, BR-STUDY-010, BR-STUDY-021, BR-STUDY-072 |
| IT-PLAT-004 | `13-platform-boundaries.md` | READY | `DEVICE-E2E` | IT-NAV-005 | SETUP-EMPTY | CLEAN-RESET | UC-DECK-003 |
| IT-PLAT-005 | `13-platform-boundaries.md` | READY | `DEVICE-E2E` | IT-NAV-010 | SETUP-EMPTY | CLEAN-RESET | UC-STUDY-001 A3, BR-STUDY-014 |
| IT-PLAT-006 | `13-platform-boundaries.md` | READY | `DEVICE-E2E` | — | SETUP-EMPTY | CLEAN-RESET | UC-DECK-001, UC-CARD-001, UC-STUDY-001 |
| IT-PLAT-009 | `13-platform-boundaries.md` | READY | `DEVICE-E2E` | — | SETUP-EMPTY | CLEAN-RESET | — |

## Bất biến của danh mục

- Mỗi tiêu đề `## IT-...` trong mười hai tệp kịch bản MUST có đúng một dòng trong danh mục.
- Cột `Profile` MUST là `HOST-FLOW`, `HOST-WIDGET` hoặc `DEVICE-E2E`, hoặc một cặp trong số đó khi kịch bản được tách.
- Kịch bản có `Dẫn xuất` khác `—` MUST giữ nguyên truy vết của kịch bản gốc.
- Danh mục MUST NOT chứa ID không có kịch bản gốc.
- Mức sẵn sàng, hồ sơ thực thi, chuẩn bị và dọn dẹp MUST dùng giá trị được định nghĩa
  trong hướng dẫn thực thi.
- Cột truy vết MUST liệt kê UC hoặc BR khi kịch bản kiểm một luật nghiệp vụ cụ
  thể. Kịch bản chỉ kiểm ranh giới nền tảng hoặc trải nghiệm thuần UI, không
  gắn với một UC/BR đơn lẻ, MAY để `—`.
- Khi thêm kịch bản, agent MUST cập nhật danh mục trong cùng thay đổi.
