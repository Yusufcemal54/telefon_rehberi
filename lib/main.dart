import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Telefon Rehberi Uygulaması',
            theme: ThemeData(
                primarySwatch: Colors.blue,
            ),
            home: MyHomePage(),
        );
    }
}

class MyHomePage extends StatefulWidget {
    @override
    _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
    Iterable<Contact>? _contacts;
    String _inputNumber = '';
    TextEditingController _numberController = TextEditingController();

    @override
    void initState() {
        super.initState();
        _requestPermissions();
    }

    void _requestPermissions() async {
        final permissionStatus = await Permission.contacts.request();
        if (permissionStatus == PermissionStatus.granted) {
            _getContacts();
        } else {
            
            showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                    title: Text('İzinler Gerekli'),
                    content: Text('Bu uygulama rehber erişimi için izin gerektirir.'),
                    actions: <Widget>[
                        TextButton(
                            child: Text('Reddet'),
                            onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                            child: Text('Ayarlar'),
                            onPressed: () => openAppSettings(),
                        ),
                    ],
                ),
            );
        }
    }

    void _getContacts() async {
        Iterable<Contact> contacts = await ContactsService.getContacts(withThumbnails: false);
        if (mounted) {
            setState(() {
                _contacts = contacts;
            });
        }
    }

    void _callNumber(String? number) async {
        if (number != null && number.isNotEmpty) {
            final Uri uri = Uri.parse('tel:$number');
            if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
            } else {
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                        title: Text('Hata'),
                        content: Text('Arama başlatılamıyor.'),
                        actions: [
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Tamam'),
                            ),
                        ],
                    ),
                );
            }
        }
    }

    void _addContact(String name, String phoneNumber) async {
        if (name.isNotEmpty) {
            Contact newContact = Contact(
                displayName: name,
                phones: [Item(label: 'mobile', value: phoneNumber)],
            );
            await ContactsService.addContact(newContact);
          
            _getContacts();
        } else {
          
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                    title: Text('Geçersiz İsim'),
                    content: Text('Lütfen geçerli bir isim girin.'),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Tamam'),
                        ),
                    ],
                ),
            );
        }
    }

    String _cleanPhoneNumber(String phoneNumber) {
       
        return phoneNumber.replaceAll(RegExp(r'[\s\W]'), '');
    }

    void _checkNumber() {
        Contact? matchingContact;
        String cleanedInputNumber = _cleanPhoneNumber(_inputNumber);
        
        for (var contact in _contacts!) {
            final phones = contact.phones;
            if (phones != null && phones.isNotEmpty) {
                final phone = phones.first.value;
                
                if (_cleanPhoneNumber(phone!) == cleanedInputNumber) {
                    matchingContact = contact;
                    break;
                }
            }
        }
        
        if (matchingContact != null) {
          
            showDialog(
                context: context,
                builder: (context) {
                    return AlertDialog(
                        title: Text('Zaten Kayıtlı'),
                        content: Text(
                            'Zaten bu numara "${matchingContact!.displayName}" adıyla kayıtlı.',
                        ),
                        actions: [
                            TextButton(
                                onPressed: () {
                                    Navigator.of(context).pop();
                                    _callNumber(_inputNumber);
                                },
                                child: Text('Ara'),
                            ),
                        ],
                    );
                },
            );
        } else {
            
            showDialog(
                context: context,
                builder: (context) {
                    TextEditingController nameController = TextEditingController();
                    return AlertDialog(
                        title: Text('Kayıt Yap'),
                        content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Text('Bu numara kayıtlı değil.'),
                                TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(
                                        hintText: 'Ad ve soyad girin',
                                    ),
                                ),
                            ],
                        ),
                        actions: [
                            TextButton(
                                onPressed: () {
                                    Navigator.of(context).pop();
                                    if (nameController.text.isNotEmpty) {
                                        _addContact(nameController.text, _inputNumber);
                                    } else {
                                        
                                        showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                title: Text('Geçersiz İsim'),
                                                content: Text('Lütfen geçerli bir isim girin.'),
                                                actions: [
                                                    TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: Text('Tamam'),
                                                    ),
                                                ],
                                            ),
                                        );
                                    }
                                },
                                child: Text('Kayıt Et'),
                            ),
                        ],
                    );
                },
            );
        }
    }

    void _showKeypad() {
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
                return SingleChildScrollView(
                    child: Container(
                        padding: EdgeInsets.all(16),
                        
                        height: MediaQuery.of(context).size.height * 0.75,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                TextField(
                                    controller: _numberController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                        hintText: 'Girilen numara',
                                    ),
                                ),
                                SizedBox(height: 10),
                                _buildKeypadRow(['1', '2', '3']),
                                _buildKeypadRow(['4', '5', '6']),
                                _buildKeypadRow(['7', '8', '9']),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        _buildKeypadButton('*'),
                                        _buildKeypadButton('0'),
                                        _buildKeypadButton('#'),
                                    ],
                                ),
                                
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        ElevatedButton(
                                            onPressed: () {
                                                setState(() {
                                                    if (_inputNumber.isNotEmpty) {
                                                        _inputNumber = _inputNumber.substring(0, _inputNumber.length - 1);
                                                        _numberController.text = _inputNumber;
                                                    }
                                                });
                                            },
                                            child: Icon(Icons.backspace),
                                            style: ElevatedButton.styleFrom(
                                                shape: CircleBorder(),
                                                padding: EdgeInsets.all(20),
                                            ),
                                        ),
                                    ],
                                ),
                                ElevatedButton(
                                    onPressed: () {
                                        Navigator.of(context).pop();
                                        _checkNumber();
                                    },
                                    child: Text('Numarayı Kontrol Et'),
                                ),
                            ],
                        ),
                    ),
                );
            },
        );
    }

    Widget _buildKeypadRow(List<String> keys) {
        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: keys.map((key) {
                return _buildKeypadButton(key);
            }).toList(),
        );
    }

    Widget _buildKeypadButton(String key) {
        return ElevatedButton(
            onPressed: () {
                setState(() {
                    if (key == '*') {
                        
                    } else if (key == '#') {
                        
                    } else {
                        _inputNumber += key;
                    }
                    _numberController.text = _inputNumber;
                });
            },
            child: Text(key),
            style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(20),
                textStyle: TextStyle(fontSize: 20),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('Telefon Rehberi Uygulaması'),
            ),
            body: _contacts != null
                ? (_contacts!.isNotEmpty
                    ? ListView.builder(
                        itemCount: _contacts!.length,
                        itemBuilder: (context, index) {
                            Contact? contact = _contacts!.elementAt(index);
                            return ListTile(
                                title: Text(contact.displayName ?? ''),
                                trailing: IconButton(
                                    icon: Icon(Icons.call),
                                    onPressed: () {
                                        final phones = contact.phones;
                                        if (phones != null && phones.isNotEmpty) {
                                            final phoneNumber = phones.first.value;
                                            _callNumber(phoneNumber);
                                        }
                                    },
                                ),
                            );
                        },
                    )
                    : Center(child: Text('Rehberde kişi bulunamadı.')))
                : Center(child: CircularProgressIndicator()),
            floatingActionButton: FloatingActionButton(
                onPressed: _showKeypad,
                child: Icon(Icons.keyboard),
                backgroundColor: Colors.green,
                tooltip: 'Tuş takımı aç',
            ),
        );
    }
}
