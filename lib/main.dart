import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // สำหรับการจัดการกับ JSON
import 'ExchangeRate.dart';
import 'MoneyBox.dart';
import 'FoodMenu.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "My App",
      home: MyHomePage(),
      theme: ThemeData(primarySwatch: Colors.purple),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ExchangeRate? _dataFromAPI;
  double balance = 1000; // เงินคงเหลือเริ่มต้น

  @override
  void initState() {
    super.initState();
    getExchangeRate();
  }

  Future<ExchangeRate> getExchangeRate() async {
    var url = Uri.parse("https://api.exchangeratesapi.io/latest?base=THB");
    var response = await http.get(url);

    if (response.statusCode == 200) {
      _dataFromAPI = exchangeRateFromJson(response.body);
      return _dataFromAPI!;
    } else {
      throw Exception('Failed to load exchange rate');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<FoodMenu> foodMenuList = [
      FoodMenu("กุ้งเผา", "500", "images/assets/picture1.jpg"),
      FoodMenu("กะเพราหมู", "50", "images/assets/picture2.jpg"),
      FoodMenu("ส้มตำ", "65", "images/assets/picture3.jpg"),
      FoodMenu("ผัดไทย", "70", "images/assets/picture4.jpg"),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("แปลงสกุลเงินและเมนูอาหาร",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // แถบสีแดงที่เพิ่มขึ้น
            Container(
              color: Colors.red,
              padding: EdgeInsets.all(8.0),
              child: Text(
                "ยินดีต้อนรับสู่แอปของผมครับ",
                style: TextStyle(color: Colors.black, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            FutureBuilder(
              future: getExchangeRate(),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    var result = snapshot.data;
                    double amount = 10000;

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          MoneyBox(
                            title: "THB",
                            amount: amount,
                            color: Colors.lightBlue,
                            size: 150,
                          ),
                          SizedBox(height: 5),
                          MoneyBox(
                            title: "USD",
                            amount: amount * result.rates["USD"],
                            color: Colors.green,
                            size: 100,
                          ),
                          SizedBox(height: 5),
                          MoneyBox(
                            title: "EUR",
                            amount: amount * result.rates["EUR"],
                            color: Colors.red,
                            size: 100,
                          ),
                          SizedBox(height: 5),
                          MoneyBox(
                            title: "GBP",
                            amount: amount * result.rates["GBP"],
                            color: Colors.pink,
                            size: 100,
                          ),
                          SizedBox(height: 5),
                          MoneyBox(
                            title: "JPY",
                            amount: amount * result.rates["JPY"],
                            color: Colors.orange,
                            size: 100,
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                }
                return LinearProgressIndicator();
              },
            ),
            SizedBox(height: 20),
            Text("เมนูอาหาร",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: foodMenuList
                    .map((foodItem) => foodMenuItem(
                        foodItem.img, foodItem.name, foodItem.price))
                    .toList(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // นำไปสู่หน้าบัญชีของฉันพร้อมกับยอดเงินคงเหลือ
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyAccountPage(balance: balance),
                  ),
                );
              },
              child: Text("ไปหน้าบัญชีของฉัน"),
            ),
            ElevatedButton(
              onPressed: () {
                // นำไปสู่หน้าที่ 3
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyThirdPage(),
                  ),
                );
              },
              child: Text("ไปหน้าที่3 ข้อมูลเกี่ยวกับแอป"),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสำหรับส่งคำสั่งซื้อไปที่ Backend
  Future<void> sendFoodSelectionToBackend(String foodName, String price) async {
    var url = Uri.parse("https://your-backend-api.com/food-selection");
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'food_name': foodName,
        'price': price,
      }),
    );

    if (response.statusCode == 200) {
      print("ส่งคำสั่งสำเร็จ");
    } else {
      print("เกิดข้อผิดพลาดในการส่งคำสั่ง");
    }
  }

  Widget foodMenuItem(String imagePath, String name, String price) {
    return GestureDetector(
      onTap: () {
        // เรียกฟังก์ชันส่งข้อมูลไปยัง Backend
        sendFoodSelectionToBackend(name, price);

        // ลดยอดเงินคงเหลือตามราคาที่เลือก
        setState(() {
          balance -= double.parse(price);
        });

        // แสดง SnackBar เมื่อผู้ใช้กดเลือกเมนู
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('คุณได้เลือกอาหาร $name'),
            duration: Duration(seconds: 2), // เวลาแสดง SnackBar
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 20)),
                Text("ราคา $price", style: TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// สร้างหน้าถัดไป "บัญชีของฉัน"
class MyAccountPage extends StatelessWidget {
  final double balance;

  MyAccountPage({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("บัญชีของฉัน"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "ยอดเงินคงเหลือ",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "$balance บาท",
              style: TextStyle(fontSize: 30, color: Colors.green),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // ปุ่มกลับไปหน้าแรก
              },
              child: Text("กลับไปหน้าแรก"),
            ),
            ElevatedButton(
              onPressed: () {
                // นำไปสู่หน้าที่ 3
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MyThirdPage(balance: balance), // ส่งยอดเงิน
                  ),
                );
              },
              child: Text("ไปหน้าถัดไป"),
            ),
          ],
        ),
      ),
    );
  }
}

// หน้าที่ 3
class MyThirdPage extends StatelessWidget {
  final double balance;

  MyThirdPage({this.balance = 0}); // รับค่า balance มาจากหน้าอื่น

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ข้อมูลเกี่ยวกับแอป"),
      ),
      body: Container(
        color: Colors.orange, // เปลี่ยนสีพื้นหลังเป็นสีส้ม
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "แอปนี้ถูกทำขึ้นเพื่อเรียนรู้การใช้ภาษา Dart และพัฒนาความสามารถของตนเองครับ เช่น การใช้ Widget หรือ Scaffold เป็นต้นครับ และอาจจะได้นำไปต่อยอดในอนาคตครับ ขอบคุณที่สละเวลามาชมครับ",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // ย้อนกลับไปหน้าบัญชีของฉัน
                },
                child: Text("ย้อนกลับไปหน้าที่ 2"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(
                      context, (route) => route.isFirst); // กลับไปหน้าแรก
                },
                child: Text("กลับไปหน้าแรก"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
