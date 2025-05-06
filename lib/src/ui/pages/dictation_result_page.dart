import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/models/error_type.dart';
import 'package:dication/src/core/models/text_model.dart';
import 'package:dication/src/ui/pages/main_page.dart';
import 'package:dication/src/ui/widgets/countdown_widget.dart';
import 'package:dication/src/ui/widgets/primary_button.dart';
import 'package:flutter/material.dart';

import '../../core/services/dictation_manager.dart';

class DictationResultPage extends StatefulWidget {
  final DiktantEvaluator evaluator;
  final TextModel text;

  const DictationResultPage({super.key, required this.evaluator, required this.text});

  @override
  State<DictationResultPage> createState() => _DictationResultPageState();
}

class _DictationResultPageState extends State<DictationResultPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        AppRouter.open(context, MainPage());
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontFamily: boldFamily,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(color: Colors.white),
          title: Text("Natija"),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                widget.text.title,
                style: TextStyle(
                  fontSize: context.isDesktop ? 24 : 18,
                  fontFamily: boldFamily,
                ),
              ),
              Row(
                spacing: 8,
                children: [
                  Text(
                    "Grafik xatoliklar soni: ",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: mediumFamily,
                    ),
                  ),
                  Text(
                    "${widget.evaluator.grafikErrorCount} ta",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: boldFamily,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 8,
                children: [
                  Text(
                    "Imloviy xatoliklar soni: ",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: mediumFamily,
                    ),
                  ),
                  Text(
                    "${widget.evaluator.imloErrorCount} ta",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: boldFamily,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 8,
                children: [
                  Text(
                    "Uslubiy xatoliklar soni: ",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: mediumFamily,
                    ),
                  ),
                  Text(
                    "${widget.evaluator.uslubiyErrorCount} ta",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: boldFamily,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 8,
                children: [
                  Text(
                    "Punktuatsion xatoliklar soni: ",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: mediumFamily,
                    ),
                  ),
                  Text(
                    "${widget.evaluator.punktuatsionErrorCount} ta",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: boldFamily,
                    ),
                  ),
                ],
              ),
              if (widget.evaluator.getDetailedErrors().isNotEmpty) SizedBox(),
              if (widget.evaluator.getDetailedErrors().isNotEmpty)
                Text(
                  "Xatoliklar",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: mediumFamily,
                  ),
                ),
              for (final item in widget.evaluator.getDetailedErrors())
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).highlightColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(8),
                  child: Column(
                    spacing: 4,
                    children: [
                      Row(
                        children: [
                          Text("Aslida: ", style: TextStyle(fontFamily: regularFamily)),
                          Text(item.originalFragment, style: TextStyle(fontFamily: boldFamily)),
                        ],
                      ),
                      Row(
                        children: [
                          Text("Siz kiritgan: ", style: TextStyle(fontFamily: regularFamily)),
                          Text(item.userFragment, style: TextStyle(fontFamily: boldFamily)),
                        ],
                      ),
                      Row(
                        children: [
                          Text("Xatolik turi: ", style: TextStyle(fontFamily: regularFamily)),
                          Text(item.type.toName, style: TextStyle(fontFamily: boldFamily)),
                        ],
                      ),

                      Row(
                        children: [
                          Text("Nima xatolik: ", style: TextStyle(fontFamily: regularFamily)),
                          Text(item.description, style: TextStyle(fontFamily: boldFamily)),
                        ],
                      ),

                    ],
                  ),
                ),
              SizedBox(),
              Row(
                spacing: 8,
                children: [
                  Text(
                    "Ball:",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: mediumFamily,
                    ),
                  ),
                  Text(
                    widget.evaluator.evaluate100PointScaleMethod3().toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: boldFamily,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 8,
                children: [
                  Text(
                    "Baho:",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: mediumFamily,
                    ),
                  ),
                  Text(
                    widget.evaluator.evaluate5PointScale().toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: boldFamily,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              PrimaryButton(
                title: "Bosh sahifaga",
                onTap: ()=> AppRouter.open(context, MainPage()),
              )
            ],
          ),
        ),
      ),
    );
  }
}
