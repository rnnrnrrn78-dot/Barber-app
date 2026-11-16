import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBZQksZyYBDeHJxLMpeoe1qAF0S0xNaTco",
      appId: "1:43787917850:web:7f45bc50a7b1f97e048fa3",
      messagingSenderId: "43787917850",
      projectId: "barber-booking-3f3cb",
      storageBucket: "barber-booking-3f3cb.firebasestorage.app",
    ),
  );
  runApp(const BarberApp());
}

class BarberApp extends StatelessWidget {
  const BarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(primary: Colors.amber),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isNo = true;
  int tab = 0;
  bool unlocked = false;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final pinCtrl = TextEditingController();

  DateTime date = DateTime.now();
  String barber = 'Elias';
  int srvIdx = 0;
  String time = '14:00';
  bool isLoading = false;

  final bookingsRef = FirebaseFirestore.instance.collection('bookings');

  Future<void> save() async {
    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNo ? 'Fyll ut navn og telefon' : 'Enter name and phone'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);
    final dStr = '${date.day}/${date.month}/${date.year}';

    try {
      final existing = await bookingsRef
          .where('date', isEqualTo: dStr)
          .where('time', isEqualTo: time)
          .where('barber', isEqualTo: barber)
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isNo ? 'Dette tidspunktet er opptatt!' : 'Time slot already booked!'), backgroundColor: Colors.orange),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      final srvs = isNo
          ? ['Hårklipp (350 kr)', 'Skjegg (200 kr)', 'Full pakke (500 kr)']
          : ['Haircut (350 NOK)', 'Beard (200 NOK)', 'Full Package (500 NOK)'];

      await bookingsRef.add({
        'name': nameCtrl.text,
        'phone': phoneCtrl.text,
        'barber': barber,
        'service': srvs[srvIdx],
        'date': dStr,
        'time': time,
        'createdAt': FieldValue.serverTimestamp(),
      });

      nameCtrl.clear();
      phoneCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNo ? 'Bestilling bekreftet!' : 'Booking confirmed!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final barbers = ['Elias', 'Omar', 'Sander'];
    final srvs = isNo
        ? ['Hårklipp (350 kr)', 'Skjegg (200 kr)', 'Full pakke (500 kr)']
        : ['Haircut (350 NOK)', 'Beard (200 NOK)', 'Full Package (500 NOK)'];
    final times = ['10:00', '11:30', '13:00', '14:00', '15:30', '17:00'];

    return Scaffold(
      appBar: AppBar(
        title: Text(isNo ? 'Elias Frisør' : 'Elias Barber'),
        actions: [
          TextButton(
            onPressed: () => setState(() => isNo = !isNo),
            child: Text(isNo ? 'EN' : 'NO', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: tab == 0
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: isNo ? 'Fullt navn' : 'Full Name', border: const OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: isNo ? 'Telefonnummer' : 'Phone Number', border: const OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: barbers.map((b) => ChoiceChip(label: Text(b), selected: barber == b, onSelected: (_) => setState(() => barber = b))).toList(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: srvIdx,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: List.generate(srvs.length, (i) => DropdownMenuItem(value: i, child: Text(srvs[i]))),
                    onChanged: (v) => setState(() => srvIdx = v!),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                      if (d != null) setState(() => date = d);
                    },
                    child: Text('${date.day}/${date.month}/${date.year}'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: times.map((t) => ChoiceChip(label: Text(t), selected: time == t, onSelected: (_) => setState(() => time = t))).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : save,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: isLoading ? const CircularProgressIndicator() : Text(isNo ? 'BEKREFT BESTILLING' : 'CONFIRM BOOKING', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          : !unlocked
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(controller: pinCtrl, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN (1234)', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (pinCtrl.text == '1234') setState(() => unlocked = true);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                        child: const Text('LOGIN'),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: bookingsRef.orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) return Center(child: Text(isNo ? 'Ingen bestillinger ennå' : 'No bookings yet'));
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (ctx, i) {
                        final doc = docs[i];
                        final b = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text('${b['name']} (${b['date']} - ${b['time']})'),
                            subtitle: Text('${b['service']} | ${b['barber']} | ${b['phone']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => bookingsRef.doc(doc.id).delete(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        selectedItemColor: Colors.amber,
        onTap: (i) => setState(() => tab = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.cut), label: isNo ? 'Bestill' : 'Book'),
          BottomNavigationBarItem(icon: const Icon(Icons.lock), label: 'Admin'),
        ],
      ),
    );
  }
}
