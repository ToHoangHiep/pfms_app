package com.pfms.api.dto;

public class TransactionDto {
    public String id;          // id trả về
    public String type;        // "income" | "expense"
    public Integer amount;     // số tiền
    public String category;    // danh mục
    public String note;        // ghi chú
    public String occurredAt;  // ISO time, ví dụ: 2026-03-13T23:30:00
}