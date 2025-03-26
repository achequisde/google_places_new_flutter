import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_places_new_flutter/constants.dart';
import 'package:google_places_new_flutter/models/places_api_response.dart';
import 'package:google_places_new_flutter/models/prediction.dart';
import 'package:google_places_new_flutter/places_query.dart';
import 'package:rxdart/rxdart.dart';

class GooglePlacesAutoCompleteTextField extends StatefulWidget {
  const GooglePlacesAutoCompleteTextField({
    super.key,
    required this.googleAPIKey,
    this.closeButton = true,
    this.predictionHorizontalOffset,
    this.predictionVerticalOffset,
    this.language,
    this.controller,
    this.debounceTime,
    this.onClick,
    this.queries,
    this.containerPadding,
    this.boxDecoration,
    this.inputDecoration,
    this.validator,
    this.textStyle,
    this.focusNode,
    this.predictionItemBuilder,
    this.separatorWidget,
    this.formSubmitCallback,
  });

  final String googleAPIKey;
  final double? predictionHorizontalOffset;
  final double? predictionVerticalOffset;
  final bool closeButton;
  final String? language;
  final TextEditingController? controller;
  final Duration? debounceTime;
  final OnClickHandler? onClick;
  final List<PlacesQuery>? queries;
  final PredictionItemBuilder? predictionItemBuilder;
  final String? Function(String?)? validator;
  final Widget? separatorWidget;
  final EdgeInsets? containerPadding;
  final BoxDecoration? boxDecoration;
  final InputDecoration? inputDecoration;
  final TextStyle? textStyle;
  final FocusNode? focusNode;
  final VoidCallback? formSubmitCallback;

  @override
  State<GooglePlacesAutoCompleteTextField> createState() =>
      _GooglePlacesAutoCompleteTextFieldState();
}

class _GooglePlacesAutoCompleteTextFieldState
    extends State<GooglePlacesAutoCompleteTextField> {
  final _layerLink = LayerLink();
  final _dio = Dio();
  final subject = PublishSubject<String>();

  bool _showCloseButton = true;

  late TextEditingController _controller;

  OverlayEntry? _overlayEntry;
  List<Prediction> predictions = [];

  CancelToken? _cancelToken = CancelToken();

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();

    subject.stream
        .distinct()
        .debounceTime(widget.debounceTime ?? Duration(milliseconds: 500))
        .listen(textChanged);
  }

  void textChanged(String text) async {
    if (text.isNotEmpty) {
      getLocation(text);
    } else {
      predictions.clear();

      if (_overlayEntry != null) {
        try {
          _overlayEntry?.remove();
        } catch (e) {}
      }
    }
  }

  @override
  void dispose() {
    subject.close();

    _controller.dispose();
    _cancelToken?.cancel();
    _overlayEntry?.remove();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: widget.containerPadding,
        decoration: widget.boxDecoration ?? BoxDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                textAlignVertical: TextAlignVertical.center,
                autovalidateMode: AutovalidateMode.disabled,
                decoration: widget.inputDecoration?.copyWith(
                  suffixIcon: (widget.closeButton &&
                          _controller.text.isNotEmpty &&
                          _showCloseButton)
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                          ),
                          onPressed: clearData,
                        )
                      : null,
                ),
                style: widget.textStyle,
                focusNode: widget.focusNode,
                onFieldSubmitted: (value) {
                  if (widget.formSubmitCallback != null) {
                    widget.formSubmitCallback!();
                  }
                },
                onEditingComplete: () {
                  if (widget.formSubmitCallback != null) {
                    widget.formSubmitCallback!();
                  }
                },
                validator: widget.validator,
                onChanged: (value) {
                  subject.add(value);

                  if (widget.closeButton) {
                    setState(() {
                      _showCloseButton = value.isNotEmpty;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void getLocation(String text) async {
    if (text.isEmpty) {
      predictions.clear();
      _overlayEntry?.remove();

      return;
    }

    String url = "${Constants.apiUrl}/${Constants.queryPath}";
    final queries = widget.queries ?? [FormattedAddressQuery()];

    final query = {
      "textQuery": text,
      "languageCode": widget.language ?? "en",
    };

    final headers = {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": widget.googleAPIKey,
      "X-Goog-FieldMask": queries.map((e) => e.query).join(','),
    };

    if (_cancelToken?.isCancelled == false) {
      _cancelToken?.cancel();
      _cancelToken = CancelToken();
    }

    try {
      final response = await _dio.post(
        url,
        data: query,
        options: Options(headers: headers),
      );

      final Map<String, dynamic> data = response.data;

      if (data.containsKey("error_message")) {
        throw data;
      }

      predictions.clear();

      final places = PlacesApiResponse.fromJson(data);

      if (places.predictions!.isNotEmpty) {
        predictions.addAll(places.predictions!);
      }

      _overlayEntry = _createPredictionOverlayEntries();

      if (mounted) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    } catch (e, stackTrace) {
      print(ErrorAndStackTrace(e, stackTrace));
    }
  }

  OverlayEntry? _createPredictionOverlayEntries() {
    if (context.findRenderObject() == null) {
      return null;
    }

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height,
          width: size.width,
          child: CompositedTransformFollower(
            showWhenUnlinked: false,
            link: _layerLink,
            offset: Offset(
              0.0 + (widget.predictionHorizontalOffset ?? 0),
              size.height + (widget.predictionVerticalOffset ?? 0),
            ),
            child: Material(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                separatorBuilder: (context, index) =>
                    widget.separatorWidget ?? SizedBox(),
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  final prediction = predictions[index];

                  final body = widget.predictionItemBuilder != null
                      ? widget.predictionItemBuilder!(
                          context,
                          index,
                          prediction,
                        )
                      : Container(
                          padding: EdgeInsets.all(10.0),
                          child: Text(prediction.toString()),
                        );

                  return InkWell(
                    onTap: () {
                      widget.onClick!(prediction);
                      removePredictions();
                    },
                    child: body,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void removePredictions() {
    predictions.clear();
    _overlayEntry = _createPredictionOverlayEntries();

    Overlay.of(context).insert(_overlayEntry!);
    _overlayEntry!.markNeedsBuild();
  }

  void clearData() {
    _controller.clear();

    if (_cancelToken?.isCancelled == false) {
      _cancelToken?.cancel();
    }

    setState(() {
      predictions.clear();
      _showCloseButton = false;
    });

    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
      } catch (e) {}
    }
  }
}

typedef OnClickHandler = void Function(Prediction prediction);

typedef PredictionItemBuilder = Widget Function(
  BuildContext context,
  int index,
  Prediction prediction,
);
