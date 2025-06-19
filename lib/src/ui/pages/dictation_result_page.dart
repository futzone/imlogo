import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/models/error_type.dart';
import 'package:dication/src/core/models/work.dart';
import 'package:dication/src/ui/pages/main_page.dart';
import 'package:dication/src/ui/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DictationResultPage extends ConsumerStatefulWidget {
  final Work work;
  final bool useBack;

  const DictationResultPage(
      {super.key, this.useBack = false, required this.work});

  @override
  ConsumerState<DictationResultPage> createState() =>
      _DictationResultPageState();
}

class _DictationResultPageState extends ConsumerState<DictationResultPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.useBack) return buildBody(context);

    return WillPopScope(
      onWillPop: () async {
        AppRouter.open(context, MainPage());
        return false;
      },
      child: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    return Scaffold(
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
              widget.work.text.title,
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
                  "${widget.work.grafikErrorCount} ta",
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
                  "${widget.work.imloErrorCount} ta",
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
                  "${widget.work.uslubiyErrorCount} ta",
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
                  "${widget.work.punktuatsionErrorCount} ta",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: boldFamily,
                  ),
                ),
              ],
            ),
            if (widget.work.errors.isNotEmpty) SizedBox(),
            if (widget.work.errors.isNotEmpty)
              Text(
                "Xatoliklar",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: mediumFamily,
                ),
              ),
            for (final item in widget.work.errors)
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Aslida: ",
                            style: TextStyle(fontFamily: regularFamily)),
                        Expanded(
                            child: Text(item.originalFragment,
                                style: TextStyle(fontFamily: boldFamily))),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Siz kiritgan: ",
                            style: TextStyle(fontFamily: regularFamily)),
                        Expanded(
                            child: Text(item.userFragment,
                                style: TextStyle(fontFamily: boldFamily))),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Xatolik turi: ",
                            style: TextStyle(fontFamily: regularFamily)),
                        Expanded(
                            child: Text(item.type.toName,
                                style: TextStyle(fontFamily: boldFamily))),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Xatolik: ",
                            style: TextStyle(fontFamily: regularFamily)),
                        Expanded(
                            child: Text(item.description,
                                style: TextStyle(fontFamily: boldFamily))),
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
                  widget.work.ball.toStringAsFixed(1),
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
                  widget.work.baho.toStringAsFixed(1),
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
              onTap: () => AppRouter.open(context, MainPage()),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
