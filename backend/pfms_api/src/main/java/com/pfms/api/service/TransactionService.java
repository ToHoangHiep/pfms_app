package com.pfms.api.service;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import com.pfms.api.dto.TransactionDto;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class TransactionService {

    private Firestore db() {
        return FirestoreClient.getFirestore();
    }

    private CollectionReference col(String uid) {
        return db().collection("users").document(uid).collection("transactions");
    }

    public String create(String uid, TransactionDto dto) throws ExecutionException, InterruptedException {
        Map<String, Object> data = new HashMap<>();
        data.put("type", dto.type);
        data.put("amount", dto.amount);
        data.put("category", dto.category);
        data.put("note", dto.note);
        data.put("occurredAt", dto.occurredAt);
        data.put("createdAt", Instant.now().toString());

        DocumentReference ref = col(uid).document(); // auto id
        ApiFuture<WriteResult> f = ref.set(data);
        f.get();

        return ref.getId();
    }

    public List<TransactionDto> list(String uid) throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> f = col(uid)
                .orderBy("occurredAt", Query.Direction.DESCENDING)
                .get();

        List<QueryDocumentSnapshot> docs = f.get().getDocuments();
        List<TransactionDto> out = new ArrayList<>();

        for (QueryDocumentSnapshot d : docs) {
            out.add(mapDocToDto(d));
        }
        return out;
    }

    public TransactionDto getById(String uid, String id) throws ExecutionException, InterruptedException {
        DocumentSnapshot d = col(uid).document(id).get().get();
        if (!d.exists()) return null;

        TransactionDto dto = new TransactionDto();
        dto.id = d.getId();
        dto.type = d.getString("type");
        Long amt = d.getLong("amount");
        dto.amount = amt == null ? null : amt.intValue();
        dto.category = d.getString("category");
        dto.note = d.getString("note");
        dto.occurredAt = d.getString("occurredAt");
        return dto;
    }

    // UPDATE: chỉ update các field được gửi lên (không ghi đè toàn bộ)
    public void update(String uid, String id, TransactionDto dto) throws ExecutionException, InterruptedException {
        Map<String, Object> data = new HashMap<>();

        if (dto.type != null) data.put("type", dto.type);
        if (dto.amount != null) data.put("amount", dto.amount);
        if (dto.category != null) data.put("category", dto.category);
        if (dto.note != null) data.put("note", dto.note);
        if (dto.occurredAt != null) data.put("occurredAt", dto.occurredAt);

        // Không có gì để update thì thôi
        if (data.isEmpty()) return;

        ApiFuture<WriteResult> f = col(uid).document(id).update(data);
        f.get();
    }

    public void delete(String uid, String id) throws ExecutionException, InterruptedException {
        ApiFuture<WriteResult> f = col(uid).document(id).delete();
        f.get();
    }

    // helper
    private TransactionDto mapDocToDto(DocumentSnapshot d) {
        TransactionDto dto = new TransactionDto();
        dto.id = d.getId();
        dto.type = d.getString("type");
        Long amt = d.getLong("amount");
        dto.amount = amt == null ? null : amt.intValue();
        dto.category = d.getString("category");
        dto.note = d.getString("note");
        dto.occurredAt = d.getString("occurredAt");
        return dto;
    }
}