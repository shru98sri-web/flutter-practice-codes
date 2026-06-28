package com.example.firebase_practice

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()

//import android.os.Bundle
//import androidx.appcompat.app.AppCompatActivity
//import com.google.firebase.analytics.FirebaseAnalytics
//import com.google.firebase.analytics.ktx.analytics
//import com.google.firebase.ktx.Firebase
//
//class MainActivity : AppCompatActivity() {
//
//    private lateinit var firebaseAnalytics: FirebaseAnalytics
//
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState: Bundle?)
//        setContentView(R.layout.activity_main)
//
//        firebaseAnalytics = Firebase.analytics
//
//        val bundle = Bundle()
//        bundle.putString(FirebaseAnalytics.Param.ITEM_ID, "id_123")
//        bundle.putString(FirebaseAnalytics.Param.ITEM_NAME, "main_screen")
//        firebaseAnalytics.logEvent(FirebaseAnalytics.Event.SELECT_CONTENT, bundle)
//    }
//}
