import 'package:flutter/material.dart';
import 'package:healthlog/data/db.dart';
import 'package:healthlog/model/sugar.dart';
import 'package:healthlog/view/theme/globals.dart';

class SGHelper {
  static Future<void> statefulBpBottomModal(BuildContext context,
      {required int userid,
      required Function callback,
      required GlobalKey<RefreshIndicatorState> refreshIndicatorKey}) async {
    final formKey = GlobalKey<FormState>();
    double reading = 0.00;
    String beforeAfter = '';
    // String fastingNormalReading = '60 - 110';
    // String afterFastingNormalReading = '70 - 140';
    String fastGroup = "";
    String unit = "mg/dL";
    String unitGroup = "mg/dL";
    String comment = "";

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: ((context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              height: 450,
              width: MediaQuery.of(context).size.width / 1.25,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          child: RadioListTile<String>(
                              title: const Text("Before"),
                              value: "before",
                              groupValue: fastGroup,
                              onChanged: (String? value) {
                                setState(() {
                                  beforeAfter = fastGroup = value.toString();
                                });
                              }),
                        ),
                        SizedBox(
                          width: 150,
                          child: RadioListTile<String>(
                            title: const Text("After"),
                            value: "after",
                            groupValue: fastGroup,
                            onChanged: (String? value) {
                              setState(() {
                                beforeAfter = fastGroup = value.toString();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 40, right: 40),
                      child: TextFormField(
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter blood sugar reading';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: (unit == 'mg/dL' &&
                                    beforeAfter == 'before')
                                ? '60-110'
                                : (unit == 'mg/dL' && beforeAfter == 'after')
                                    ? '70-140'
                                    : (unitGroup == 'mmol/L' &&
                                            beforeAfter == 'before')
                                        ? '3.33-6.11'
                                        : (unitGroup == 'mmol/L' &&
                                                beforeAfter == 'after')
                                            ? '3.88-7.77'
                                            : '',
                            suffixText: unitGroup,
                            label: const Text('Blood Sugar'),
                          ),
                          onChanged: (String? value) {
                            setState(
                                () => reading = double.parse(value.toString()));
                          }),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          child: RadioListTile<String>(
                              title: const Text("mmol/L"),
                              value: "mmol/L",
                              groupValue: unitGroup,
                              onChanged: (String? value) {
                                setState(() {
                                  unit = unitGroup = value.toString();
                                });
                              }),
                        ),
                        SizedBox(
                          width: 150,
                          child: RadioListTile<String>(
                            title: const Text("mg/dL"),
                            selected: true,
                            value: "mg/dL",
                            groupValue: unitGroup,
                            onChanged: (String? value) {
                              setState(() {
                                unit = unitGroup = value.toString();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 40, right: 40),
                      child: TextFormField(
                          decoration: const InputDecoration(
                              hintText: 'What did you eat',
                              label: Text('Comments')),
                          onChanged: (String? value) {
                            setState(() => comment = value.toString());
                          }
                          // (value) {
                          //   setState(() {
                          //     comment = value;
                          //   });
                          // },
                          ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await DatabaseHandler.instance
                              .insertSg(Sugar(
                                  user: userid,
                                  type: 'sugar',
                                  content: SG(
                                      reading: reading,
                                      beforeAfter: beforeAfter,
                                      unit: unit),
                                  date: DateTime.now().toIso8601String(),
                                  comments: comment))
                              .whenComplete(() {
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            WidgetsBinding.instance.addPostFrameCallback((_) =>
                                refreshIndicatorKey.currentState?.show());
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Data')),
                          );
                        }
                      },
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      }),
    );
  }

  static Future<void> showRecord(
      BuildContext context, int entryid, String unit) async {
    late DatabaseHandler handler;
    late Future<List<Sugar>> sg;
    Future<List<Sugar>> getList() async {
      handler = DatabaseHandler.instance;
      return await handler.sugarEntry(entryid);
    }

    sg = getList();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return FutureBuilder<List<Sugar>>(
            future: sg,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final entry = snapshot.data ?? [];
                  String reading = GlobalMethods.convertUnit(unit,
                          entry.first.content.unit, entry.first.content.reading)
                      .toString();

                  return AlertDialog(
                    title: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.receipt_rounded,
                            size: 25,
                            color: Colors.green,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Sugar Record: $entryid'),
                        ),
                      ],
                    ),
                    content: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                  '${entry.first.content.beforeAfter.toUpperCase()}:',
                                  style: const TextStyle(
                                    fontSize: 20,
                                  )),
                              Text(
                                '$reading $unit',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: (entry.first.content.beforeAfter ==
                                                    'before' &&
                                                entry.first.content.reading >
                                                    110) ||
                                            (entry.first.content.beforeAfter ==
                                                    'after' &&
                                                entry.first.content.reading >
                                                    140)
                                        ? Colors.red
                                        : Colors.green),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: SizedBox(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  unit == 'mg/dL'
                                      ? const Text('Fasting: 60-110 mg/dL')
                                      : const Text('Fasting: 3.33-6.11 mmol/L'),
                                  unit == 'mg/dL'
                                      ? const Text('After: 70-140 mg/dL')
                                      : const Text('After: 3.88-7.77 mmol/L')
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 25.0),
                            child: SizedBox(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                      'Date: ${DateTime.parse(entry.first.date).year}-${DateTime.parse(entry.first.date).month}-${DateTime.parse(entry.first.date).day}'),
                                  Text(
                                      'Time: ${DateTime.parse(entry.first.date).hour}:${DateTime.parse(entry.first.date).minute}')
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  );
                }
              } else {
                return const CircularProgressIndicator(); // Or any loading indicator widget
              }
            },
          );
        });
  }
}
