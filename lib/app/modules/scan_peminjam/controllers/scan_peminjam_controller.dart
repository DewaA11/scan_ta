import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanPeminjamController extends GetxController {
  RxBool isLoading = false.obs;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<DocumentSnapshot<Object?>> getUserDoc() async {
    String uid = auth.currentUser!.uid;
    DocumentReference user = firestore.collection("Users").doc(uid);
    return user.get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamStokBarang() async* {
    yield* firestore.collection("products").snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamHistoryBarang() async* {
    yield* firestore.collection("history").snapshots();
  }

  Future<int> getProductQty(String code) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
          .collection("products")
          .where("code", isEqualTo: code)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot<Map<String, dynamic>> productDoc =
            querySnapshot.docs.first;
        return productDoc.data()?["qty"] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> data) async {
    try {
      int productQty = await getProductQty(data["code"]);

      if (productQty >= data["qty"]) {
        // Mengurangi qty produk di Firestore
        await firestore
            .collection("products")
            .where("code", isEqualTo: data["code"])
            .limit(1)
            .get()
            .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            DocumentSnapshot<Map<String, dynamic>> doc = snapshot.docs.first;
            int newQty = (productQty - data["qty"])
                .toInt(); // Mengurangi qty sesuai dengan jumlah yang diambil
            doc.reference.update({
              "qty": newQty,
            });
          }
        });

// Menambahkan produk ke koleksi "history"
        var hasil = await firestore.collection("history").add({
          "code": data["code"],
          "uid": data["uid"],
          "user": data["user"],
          "name": data["name"],
          "qty": data["qty"],
          "typ": data["typ"],
          "date": DateTime.now().toIso8601String(),
        });
        await firestore.collection("history").doc(hasil.id).update({
          "productId": hasil.id,
        });
        return {
          "error": false,
          "message": "Berhasil menambah produk.",
        };
      } else {
        return {
          "error": true,
          "message": "Stok produk tidak mencukupi.",
        };
      }
    } catch (e) {
      return {
        "error": true,
        "message": "Tidak dapat menambah produk.",
      };
    }
  }
}
