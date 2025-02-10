import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukk_2025/main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _usernameError;
  String? _passwordError;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _login() async {
    setState(() {
      _usernameError = null;
      _passwordError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      final response = await supabase
          .from('user')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _usernameError = "Username tidak terdaftar";
        });
      } else if (response['password'] != password) {
        setState(() {
          _passwordError = "Password salah, coba lagi";
        });
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', response['username']);

        //Menampilkan Snackbar untuk info sukses login
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Login berhasil'),
          backgroundColor: Colors.green,
        ));

        //Setelah login diarahka ke mainpage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      setState(() {
        _usernameError = "Terjadi kesalahan, coba lagi nanti";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 85, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text("Selamat Datang", style: _textStyle(24, FontWeight.bold)),
                Text("Silahkan Login",
                    style: _textStyle(16, FontWeight.normal)),
                const SizedBox(height: 45),
                _buildTextField(
                    "Username", _usernameController, _usernameError),
                const SizedBox(height: 10),
                _buildPasswordField(),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 70, vertical: 15),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login", style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _textStyle(double fontSize, FontWeight fontWeight) {
    return TextStyle(
        fontSize: fontSize, fontWeight: fontWeight, color: Colors.blue);
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String? errorText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: label,
        labelText: label,
        errorText: errorText,
        border: const UnderlineInputBorder(),
      ),
      validator: (value) {
        if (value!.isEmpty) return '$label tidak boleh kosong';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: "Password",
        labelText: 'Password',
        errorText: _passwordError,
        border: const UnderlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Password tidak boleh kosong';
        return null;
      },
    );
  }
}
