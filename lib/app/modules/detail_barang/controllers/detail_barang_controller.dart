import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailBarangController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isLoadingDelete = false.obs;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamRole() async* {
    String uid = auth.currentUser!.uid;

    yield* firestore.collection("Users").doc(uid).snapshots();
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
          .collection("history")
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

  Future<int> getBarangQty(String code) async {
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
      int barangQty = await getBarangQty(data["code"]);

      if (productQty >= data["qty"]) {
        int updatedProductQty = (productQty - data["qty"]).toInt();
        int updatedBarangQty = (barangQty + data["qty"]).toInt();

        // Mengurangi qty produk di Firestore
        await firestore
            .collection("history")
            .where("code", isEqualTo: data["code"])
            .where("user", isEqualTo: data["user"])
            .limit(1)
            .get()
            .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            DocumentSnapshot<Map<String, dynamic>> doc = snapshot.docs.first;
            doc.reference.update({
              "qty": updatedProductQty,
            });
          }
        });

        await firestore
            .collection("products")
            .where("code", isEqualTo: data["code"])
            .limit(1)
            .get()
            .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            DocumentSnapshot<Map<String, dynamic>> doc = snapshot.docs.first;
            doc.reference.update({
              "qty": updatedBarangQty,
            });
          }
        });

        return {
          "error": false,
          "message": "Berhasil menambah produk.",
        };
      } else {
        return {
          "error": true,
          "message": "Stok produk habis.",
        };
      }
    } catch (e) {
      return {
        "error": true,
        "message": "Tidak dapat menambah produk.",
      };
    }
  }

  Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      await firestore.collection("history").doc(id).delete();
      return {
        "error": false,
        "message": "Berhasil delete product.",
      };
    } catch (e) {
      return {
        "error": true,
        "message ": "Tidak dapat delete product.",
      };
    }
  }
}
