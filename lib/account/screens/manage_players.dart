import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/styles.dart';
import '../../core/widgets/primary_button.dart';

class ManagePlayersPage extends StatelessWidget {
  const ManagePlayersPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Manage Players", style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: AppColors.primary),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_)=>const AddPlayerPage())),
      ),
      body: Center(
        child: Text("Player List goes here (Use ManageUsers pattern)", style: AppTextStyles.body),
      ),
    );
  }
}

class AddPlayerPage extends StatefulWidget {
  const AddPlayerPage({super.key});
  @override
  State<AddPlayerPage> createState() => _AddPlayerPageState();
}

class _AddPlayerPageState extends State<AddPlayerPage> {
  final _formKey = GlobalKey<FormState>();
  String nama="", position="", negara="", thumbnail="";
  int umur=0, marketValue=0, goal=0, asis=0, match=0;
  String? selectedClubId;
  List<dynamic> clubs = [];

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  void _fetchClubs() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    final response = await request.get('https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/clubs/');
    setState(() => clubs = response['data']);
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Add Player", style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField <String>(
              value: selectedClubId,
              hint: const Text("Pilih Klub"),
              items: clubs.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))).toList(),
              onChanged: (v) => setState(() => selectedClubId = v!),
              validator: (v) => v == null ? "Wajib pilih klub" : null,
              decoration: _inputDecor("Club"),
            ),
            const SizedBox(height: 12),
            TextFormField(decoration: _inputDecor("Nama Pemain"), onChanged: (v)=>nama=v),
            const SizedBox(height: 12),
            TextFormField(decoration: _inputDecor("Posisi"), onChanged: (v)=>position=v),
            const SizedBox(height: 12),
            TextFormField(decoration: _inputDecor("Negara"), onChanged: (v)=>negara=v),
            const SizedBox(height: 12),
            TextFormField(decoration: _inputDecor("Umur"), keyboardType: TextInputType.number, onChanged: (v)=>umur=int.tryParse(v)??0),
            const SizedBox(height: 12),
            TextFormField(decoration: _inputDecor("Market Value"), keyboardType: TextInputType.number, onChanged: (v)=>marketValue=int.tryParse(v)??0),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(decoration: _inputDecor("Goals"), keyboardType: TextInputType.number, onChanged: (v)=>goal=int.tryParse(v)??0)),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(decoration: _inputDecor("Assists"), keyboardType: TextInputType.number, onChanged: (v)=>asis=int.tryParse(v)??0)),
            ]),
            const SizedBox(height: 12),
            TextFormField(decoration: _inputDecor("Matches"), keyboardType: TextInputType.number, onChanged: (v)=>match=int.tryParse(v)??0),
            const SizedBox(height: 12),
            TextFormField(decoration: _inputDecor("Thumbnail URL"), onChanged: (v)=>thumbnail=v),
            
            const SizedBox(height: 30),
            PremiereButton(
              text: "SAVE PLAYER",
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await request.postJson("https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/players/create/", jsonEncode({
                    "club_id": selectedClubId,
                    "nama_pemain": nama,
                    "position": position,
                    "umur": umur,
                    "market_value": marketValue,
                    "negara": negara,
                    "jumlah_goal": goal,
                    "jumlah_asis": asis,
                    "jumlah_match": match,
                    "thumbnail": thumbnail
                  }));
                  if(context.mounted) Navigator.pop(context);
                }
              },
            )
          ],
        ),
      ),
    );
  }
}