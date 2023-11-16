import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:barcode_image/barcode_image.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cartão do SUS personalizado online - RT'),
        ),
        body: const CnsPersonalizado(),
      ),
    );
  }
}

class CnsPersonalizado extends StatefulWidget {
  const CnsPersonalizado({super.key});

  @override
  State<CnsPersonalizado> createState() => _CnsPersonalizadoState();
}

class _CnsPersonalizadoState extends State<CnsPersonalizado> {
  ImageProvider? imageProvider;
  bool loadingImage = false;
  img.Image? _image;
  String _cns = "";
  String _dtNasc = "";
  String _nome = "";
  String? _sexo;
  int _index = 0;
  List<String> imagePaths = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
    'assets/images/4.png',
    'assets/images/5.png',
    'assets/images/6.png',
    'assets/images/7.png',
    'assets/images/8.png',
    'assets/images/9.png',
  ];
  html.FileReader reader = html.FileReader();
  int counter = 0;
  Uint8List liberationMono18 = Uint8List.fromList(List.empty());
  Uint8List liberationMono24 = Uint8List.fromList(List.empty());
  Uint8List liberationMono40 = Uint8List.fromList(List.empty());

  @override
  initState() {
    super.initState();
    rootBundle.load('assets/fonts/LiberationMono18.zip').then((fontByteData) {
      liberationMono18 = Uint8List.view(fontByteData.buffer);
    });
    rootBundle.load('assets/fonts/LiberationMono24.zip').then((fontByteData) {
      liberationMono24 = Uint8List.view(fontByteData.buffer);
    });
    rootBundle.load('assets/fonts/LiberationMono40.zip').then((fontByteData) {
      liberationMono40 = Uint8List.view(fontByteData.buffer);
    });
  }

  Future<Uint8List> generatePdfWithImage() async {
    final pdf = pw.Document();
    final image = pw.ImageImage(_image!);
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.only(top: 1),
        build: (pw.Context context) {
          return pw.Flexible(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(image),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  void openPdfInBrowser(Uint8List pdfBytes) {
    final blob = html.Blob([Uint8List.fromList(pdfBytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "cns_personalizado_rt.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void downloadPdf() async {
    final pdf = await generatePdfWithImage();
    openPdfInBrowser(pdf);
  }

  void printPdf() async {
    final pdf = await generatePdfWithImage();
    Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf,
    );
  }

  Future<html.FileReader> _openFileExplorer() async {
    final completer = Completer<html.FileReader>();
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files!.length == 1) {
        final file = files[0];
        final reader = html.FileReader();
        reader.onLoadEnd.listen((e) {
          completer.complete(reader);
        });
        reader.readAsArrayBuffer(file);
      }
    });

    return completer.future;
  }

  void _insertDataIntoImage() {
    img.BitmapFont? font18 = img.BitmapFont.fromZip(liberationMono18);
    img.BitmapFont? font24 = img.BitmapFont.fromZip(liberationMono24);
    img.BitmapFont? font40 = img.BitmapFont.fromZip(liberationMono40);

    img.Image baseImage = _image!;
    int xpos = baseImage.width ~/ 100;
    int ypos = baseImage.height ~/ 100;
    img.drawString(
      y: ypos * 28,
      x: xpos * 63,
      baseImage,
      _nome,
      font: font24,
      color: img.ColorRgb8(0, 0, 0),
    );

    img.drawString(
      y: ypos * 38,
      x: xpos * 63,
      baseImage,
      'Data Nasc.: $_dtNasc           Sexo: ${_sexo![0].toUpperCase()}',
      font: font18,
      color: img.ColorRgb8(0, 0, 0),
    );
    img.drawString(
      y: ypos * 48,
      x: xpos * 63,
      baseImage,
      _cns,
      font: font40,
      color: img.ColorRgb8(0, 0, 0),
    );
    drawBarcode(baseImage, Barcode.code128(), _cns,
        y: ypos * 58, x: xpos * 63, width: xpos * 21, height: ypos * 12);
    setState(() {
      loadingImage = false;
      _image = baseImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> stepKey = GlobalKey<FormState>();
    final TextEditingController birthdateController = TextEditingController();
    final maskFormatterDtNasc = MaskTextInputFormatter(
      mask: "##/##/####",
      filter: {"#": RegExp(r'[0-9]')},
    );
    final TextEditingController cnsController = TextEditingController();
    final maskFormatterCNS = MaskTextInputFormatter(
      mask: "### #### #### ####",
      filter: {"#": RegExp(r'[0-9]')},
    );
    return Stepper(
      controlsBuilder: (context, _) {
        return Row(
          children: <Widget>[
            TextButton(
              onPressed: () {
                if (_index > 0) {
                  setState(() {
                    _index -= 1;
                  });
                }
              },
              child: const Text('Voltar'),
            ),
            TextButton(
              onPressed: () {
                if (_index == 0) {
                  if (stepKey.currentState!.validate()) {
                    setState(() {
                      _index += 1;
                    });
                  }
                } else if (_index == 1) {
                  if (_image != null) {
                    loadingImage = true;
                    setState(() {
                      _index += 1;
                    });
                    Future.delayed(const Duration(milliseconds: 400))
                        .then((_) => _insertDataIntoImage());
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Escolha uma imagem'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Próximo'),
            ),
          ],
        );
      },
      currentStep: _index,
      onStepCancel: () {},
      onStepContinue: () {},
      onStepTapped: (int index) {
        if (_index == 0) {
          if (stepKey.currentState!.validate()) {
            setState(() {
              _index += 1;
            });
          }
        } else if (_index == 1) {
          if (_image != null) {
            loadingImage = true;
            setState(() {
              _index += 1;
            });
            Future.delayed(const Duration(milliseconds: 400))
                .then((_) => _insertDataIntoImage());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.red,
                content: Text('Escolha uma imagem'),
              ),
            );
          }
        }
      },
      steps: <Step>[
        Step(
          title: const Text('Dados do cartão do SUS'),
          state: _index == 0 ? StepState.editing : StepState.complete,
          content: Form(
            key: stepKey, // Set the key to access the form's state
            child: Container(
              alignment: Alignment.centerLeft,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration:
                                const InputDecoration(label: Text("Nome")),
                            onChanged: (text) {
                              _nome = text.toUpperCase();
                            },
                            validator: (value) {
                              if (value!.isEmpty ||
                                  value.split(' ').length < 2) {
                                return 'Nome completo é necessário';
                              }
                              if (value.length > 32) {
                                return 'Nome muito grande, tente abreviar os nomes do meio';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonFormField<String>(
                            validator: (value) {
                              if (value == null) {
                                return 'Selecione o sexo';
                              }
                              return null;
                            },
                            decoration:
                                const InputDecoration(label: Text("Sexo")),
                            value: _sexo,
                            onChanged: (String? newValue) {
                              _sexo = newValue!;
                            },
                            items: <String>['Masculino', 'Feminino']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: cnsController,
                            inputFormatters: [maskFormatterCNS],
                            onChanged: (value) {
                              _cns = value;
                            },
                            decoration: const InputDecoration(labelText: "CNS"),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Cartão do SUS é obrigatório';
                              }
                              if (!isCartaoSUSValid(value)) {
                                return 'Cartão do SUS inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: birthdateController,
                            onChanged: (value) {
                              _dtNasc = value;
                            },
                            inputFormatters: [maskFormatterDtNasc],
                            decoration:
                                const InputDecoration(labelText: "Dt. Nasc"),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Data de nascimento é obrigatória';
                              }
                              if (!isBirthdateValid(birthdateController.text)) {
                                return 'Data de nascimento inválida';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Step(
          title: const Text('Selecione um modelo de cartão'),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Stack(
                  children: <Widget>[
                    if (loadingImage) // Display loading animation if loadingImage is true
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                            child: Text(
                          "Carregando imagem...",
                          style: TextStyle(fontSize: 30),
                        )),
                      )
                    else if (_image != null)
                      Image.memory(
                        Uint8List.fromList(img.encodePng(_image!)),
                        fit: BoxFit.contain,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  itemCount: imagePaths.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _loadImage(imagePaths[index]);
                        });
                      },
                      child: Image.asset(imagePaths[index]),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text("ou"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _openFileExplorer().then((reader) {
                      setState(() {
                        loadingImage = true;
                      });

                      Uint8List uint8List =
                          Uint8List.fromList(reader.result as List<int>);
                      ByteBuffer buffer = uint8List.buffer;
                      _image = img.decodeImage(buffer.asUint8List())!;
                      setState(() {
                        loadingImage = false;
                      });
                    });
                  },
                  child: const Text('Selecione uma imagem'),
                ),
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: DisclaimerText(),
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Imprima ou baixe'),
          content: (loadingImage)
              ? // Display loading animation if loadingImage is true
              const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                      child: Text(
                    "Processando imagem...",
                    style: TextStyle(fontSize: 20),
                  )),
                )
              : Center(
                  child: Column(
                    children: [
                      (_image != null)
                          ? Image.memory(
                              Uint8List.fromList(img.encodePng(_image!)))
                          : const SizedBox.shrink(),
                      const SizedBox(height: 20),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: printPdf,
                                child: const Text('Imprimir PDF'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: downloadPdf,
                                child: const Text('Download PDF'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _loadImage(String path) {
    setState(() {
      loadingImage = true;
    });
    rootBundle.load(path).then((data) {
      final Uint8List uint8List = data.buffer.asUint8List();
      final img.Image? decodedImage = img.decodePng(uint8List);
      if (decodedImage != null) {
        setState(() {
          _image = decodedImage;
        });
      }
      loadingImage = false;
    });
  }

  bool isCartaoSUSValid(String cartaoSUS) {
    cartaoSUS = cartaoSUS.replaceAll(RegExp(r'[^0-9]'), '');
    if (cartaoSUS.length != 15) {
      return false;
    }
    int sum = 0;
    for (int i = 0; i < 15; i++) {
      int digit = int.parse(cartaoSUS[i]);
      sum += digit * (15 - i);
    }
    return sum % 11 == 0;
  }

  bool isBirthdateValid(String input) {
    String cleanedInput = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedInput.length != 8) {
      return false;
    }
    int day = int.parse(cleanedInput.substring(0, 2));
    int month = int.parse(cleanedInput.substring(2, 4));
    int year = int.parse(cleanedInput.substring(4, 8));
    DateTime now = DateTime.now();
    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        year < 1900 ||
        year > now.year) {
      return false;
    }
    return true;
  }
}

class DisclaimerText extends StatelessWidget {
  const DisclaimerText({super.key});
  @override
  Widget build(BuildContext context) {
    const double fontSize = 10;
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Imagens autorais de ',
          style: const TextStyle(color: Colors.black, fontSize: fontSize),
          children: <TextSpan>[
            const TextSpan(
              text: 'papelariapersonalizadafacil',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 10),
            ),
            const TextSpan(
              text: ', você pode baixar mais modelos ',
              style: TextStyle(color: Colors.black, fontSize: fontSize),
            ),
            TextSpan(
              text: 'aqui',
              style: const TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  html.window.open(
                      'https://papelariapersonalizadafacil.com/65-modelos-gratis-de-cartao-do-sus-personalizado-para-editar-e-imprimir/',
                      "CNS Personalizado RT");
                },
            ),
          ],
        ),
      ),
    );
  }
}
