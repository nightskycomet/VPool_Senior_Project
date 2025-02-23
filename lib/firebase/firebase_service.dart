import 'package:firebase_database/firebase_database.dart';

FirebaseDatabase database = FirebaseDatabase.instance;
final firebaseApp = database.app;
final rtdb = FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: 'https://console.firebase.google.com/u/0/project/vpool-c8fdb/database/vpool-c8fdb-default-rtdb/data/~2F?fb_gclid=Cj0KCQiA_NC9BhCkARIsABSnSTYF-a4auabfDxKaXKUa8a0Jn9ZHIRv-m8rtzr5-QWE3ZdXewdpiuPUaArEcEALw_wcB');
DatabaseReference ref = FirebaseDatabase.instance.ref();