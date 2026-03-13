package com.pfms.api.controller;

import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class FirestorePingController {

    @GetMapping("/api/firestore/ping")
    public String ping() {
        Firestore db = FirestoreClient.getFirestore();
        return "Firestore OK";
    }
}