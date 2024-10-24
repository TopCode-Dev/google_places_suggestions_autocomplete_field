library autocomplete_textfield;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef AutoCompleteOverlayItemBuilder<T> = Widget Function(
    BuildContext context, T suggestion);

typedef Filter<T> = bool Function(T suggestion, String query);

typedef InputEventCallback<T> = Function(T data);

typedef StringCallback = Function(String data);

class AutoCompleteTextField<T> extends StatefulWidget {
  final StreamController<List<T>>? placeSuggestionController;
  final Filter<T>? itemFilter;
  final Comparator<T>? itemSorter;
  final StringCallback? textChanged, textSubmitted;
  final ValueSetter<bool>? onFocusChanged;
  final Function(T) itemSubmitted;
  final AutoCompleteOverlayItemBuilder<T>? itemBuilder;
  final int? suggestionsAmount;
  @override
  final GlobalKey<AutoCompleteTextFieldState<T>>? key;
  final bool? submitOnSuggestionTap, clearOnSubmit;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLength;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization? textCapitalization;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Color suggestionBackgroundColor;
  final Color suggestionDividerColor;


  const AutoCompleteTextField(
      {required this.itemSubmitted, //Callback on item selected, this is the item selected of type <T>
        @required
        this.key, //GlobalKeylobalKey used to enable addSuggestion etc
        @required
        this.placeSuggestionController, //Suggestions that will be displayed
        @required
        this.itemBuilder, //Callback to build each item, return a Widget
        @required
        this.itemSorter, //Callback to sort items in the form (a of type <T>, b of type <T>)
        @required
        this.itemFilter, //Callback to filter item: return true or false depending on input text
        this.inputFormatters,
        this.style,
        this.decoration = const InputDecoration(),
        this.textChanged, //Callback on input text changed, this is a string
        this.textSubmitted, //Callback on input text submitted, this is also a string
        this.onFocusChanged,
        this.keyboardType = TextInputType.text,
        this.suggestionsAmount =
        5, //The amount of suggestions to show, larger values may result in them going off screen
        this.submitOnSuggestionTap =
        true, //Call textSubmitted on suggestion tap, itemSubmitted will be called no matter what
        this.clearOnSubmit = true, //Clear autoCompleteTextfield on submit
        this.textInputAction = TextInputAction.done,
        this.textCapitalization = TextCapitalization.sentences,
        this.minLength = 1,
        this.controller,
        this.focusNode, required this.suggestionBackgroundColor, required this.suggestionDividerColor})
      : super(key: key);

  void clear() => key?.currentState?.clear();

  void addSuggestion(T suggestion) =>
      key?.currentState?.addSuggestion(suggestion);

  void removeSuggestion(T suggestion) =>
      key?.currentState?.removeSuggestion(suggestion);

  void updateSuggestions(List<T> suggestions) =>
      key?.currentState?.updateSuggestions(suggestions);

  void triggerSubmitted() => key?.currentState?.triggerSubmitted();

  void updateDecoration(
      {InputDecoration? decoration,
        List<TextInputFormatter>? inputFormatters,
        TextCapitalization? textCapitalization,
        TextStyle? style,
        TextInputType? keyboardType,
        TextInputAction? textInputAction}) =>
      key?.currentState?.updateDecoration(decoration!, inputFormatters!,
          textCapitalization!, style!, keyboardType!, textInputAction!);

  TextField? get textField => key?.currentState?.textField;

  @override
  State<StatefulWidget> createState() => AutoCompleteTextFieldState<T>(
      placeSuggestionController!,
      textChanged,
      textSubmitted,
      onFocusChanged,
      itemSubmitted,
      itemBuilder,
      itemSorter,
      itemFilter,
      suggestionsAmount,
      submitOnSuggestionTap,
      clearOnSubmit,
      minLength,
      inputFormatters,
      textCapitalization,
      decoration,
      style,
      keyboardType,
      textInputAction,
      controller,
      focusNode);
}

class AutoCompleteTextFieldState<T> extends State<AutoCompleteTextField> {
  final LayerLink _layerLink = LayerLink();
  StreamController<List<T>> placeSuggestionController;
  TextField? textField;
  List<T>? suggestions = [];
  StringCallback? textChanged, textSubmitted;
  ValueSetter<bool>? onFocusChanged;
  Function(T)? itemSubmitted;
  AutoCompleteOverlayItemBuilder<T>? itemBuilder;
  Comparator<T>? itemSorter;
  OverlayEntry? listSuggestionsEntry;
  List<T>? filteredSuggestions = [];
  Filter<T>? itemFilter;
  int? suggestionsAmount;
  int? minLength;
  bool? submitOnSuggestionTap, clearOnSubmit;
  TextEditingController? controller;
  FocusNode? focusNode;
  String? currentText = "";
  InputDecoration? decoration;
  List<TextInputFormatter>? inputFormatters;
  TextCapitalization? textCapitalization;
  TextStyle? style;
  TextInputType? keyboardType;
  TextInputAction? textInputAction;

  AutoCompleteTextFieldState(
      this.placeSuggestionController,
      this.textChanged,
      this.textSubmitted,
      this.onFocusChanged,
      this.itemSubmitted,
      this.itemBuilder,
      this.itemSorter,
      this.itemFilter,
      this.suggestionsAmount,
      this.submitOnSuggestionTap,
      this.clearOnSubmit,
      this.minLength,
      this.inputFormatters,
      this.textCapitalization,
      this.decoration,
      this.style,
      this.keyboardType,
      this.textInputAction,
      this.controller,
      this.focusNode) {
    try {
      placeSuggestionController.stream.listen((event) {
        suggestions = event;
      });
    } catch(e) {
      //print("Error Listening to subscribed stream");
    }
    textField = TextField(
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization!,
      decoration: decoration,
      style: style,
      keyboardType: keyboardType,
      focusNode: focusNode ?? FocusNode(),
      controller: controller ?? TextEditingController(),
      textInputAction: textInputAction,
      onChanged: (newText) {
        currentText = newText;
        updateOverlay(newText);

        if (textChanged != null) {
          textChanged!(newText);
        }
      },
      onTap: () {
        updateOverlay(currentText!);
      },
      onSubmitted: (submittedText) =>
          triggerSubmitted(submittedText: submittedText),
    );

    if (controller != null && controller?.text != null) {
      currentText = controller?.text;
    }

    textField?.focusNode?.addListener(() {
      if (onFocusChanged != null) {
        //onFocusChanged!(textField!.focusNode!.hasFocus);
      }

      if (!textField!.focusNode!.hasFocus) {
        filteredSuggestions = [];
        updateOverlay();
      } else if (!(currentText == "" || currentText == null)) {
        updateOverlay(currentText!);
      }
    });
  }

  void updateDecoration(
      InputDecoration decoration,
      List<TextInputFormatter> inputFormatters,
      TextCapitalization textCapitalization,
      TextStyle style,
      TextInputType keyboardType,
      TextInputAction textInputAction) {
    this.decoration = decoration;

    this.inputFormatters = inputFormatters;

    this.textCapitalization = textCapitalization;

    this.style = style;

    this.keyboardType = keyboardType;

    this.textInputAction = textInputAction;

    setState(() {
      textField = TextField(
        inputFormatters: this.inputFormatters,
        textCapitalization: this.textCapitalization!,
        decoration: this.decoration,
        style: this.style,
        keyboardType: this.keyboardType,
        focusNode: focusNode ?? FocusNode(),
        controller: controller ?? TextEditingController(),
        textInputAction: this.textInputAction,
        onChanged: (newText) {
          currentText = newText;
          updateOverlay(newText);

          if (textChanged != null) {
            textChanged!(newText);
          }
        },
        onTap: () {
          updateOverlay(currentText);
        },
        onSubmitted: (submittedText) =>
            triggerSubmitted(submittedText: submittedText),
      );
    });
  }

  void triggerSubmitted({submittedText}) {
    submittedText == null
        ? textSubmitted!(currentText!)
        : textSubmitted!(submittedText);

    if (clearOnSubmit!) {
      clear();
    }
  }

  void clear() {
    textField?.controller?.clear();
    currentText = "";
    updateOverlay();
  }

  void addSuggestion(T suggestion) {
    suggestions?.add(suggestion);
    updateOverlay(currentText!);
  }

  void removeSuggestion(T suggestion) {
    suggestions!.contains(suggestion)
        ? suggestions!.remove(suggestion)
        : throw "List does not contain suggestion and therefore cannot be removed";
    updateOverlay(currentText!);
  }

  void updateSuggestions(List<T> suggestions) {
    this.suggestions = suggestions;
    updateOverlay(currentText!);
  }

  void updateOverlay([String? query]) {
    if (listSuggestionsEntry == null) {
      // debugPrint('updateOverlay: ${json.encode(filteredSuggestions)}');
      final Size textFieldSize = (context.findRenderObject() as RenderBox).size;
      final width = textFieldSize.width;
      final height = textFieldSize.height;
      listSuggestionsEntry = OverlayEntry(builder: (context) {
        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, height),
            child: SizedBox(
              width: width,
              child: Card(
                child: Column(
                  children: filteredSuggestions!.map((suggestion) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: widget.suggestionDividerColor,
                            width: 1.0, //
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              color: widget.suggestionBackgroundColor,
                              padding: const EdgeInsets.all(14.0),
                              child: TextButton(
                                child: itemBuilder!(context, suggestion),
                                onPressed: () {
                                    if (submitOnSuggestionTap!) {
                                      //String? newText = suggestion?.description.toString();
                                      //textField?.controller?.text = newText;
                                      textField?.focusNode?.unfocus();
                                      itemSubmitted!(suggestion);
                                      if (clearOnSubmit!) {
                                        clear();
                                      }
                                    } else {
                                      String newText = suggestion.toString();
                                      //textField?.controller?.text = newText;
                                      textChanged!(newText);
                                    }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      }, );
      Overlay.of(context)?.insert(listSuggestionsEntry!);

    }

    filteredSuggestions = suggestions;
    getSuggestions(
        suggestions!, itemSorter!, itemFilter!, suggestionsAmount!, query ?? "-");

    listSuggestionsEntry?.markNeedsBuild();
  }

  List<T> getSuggestions(List<T> suggestions, Comparator<T> sorter,
      Filter<T> filter, int maxAmount, String query) {
    if (query.length < minLength!) {
      return [];
    }

    suggestions = suggestions.where((item) => filter(item, query)).toList()?? [];
    suggestions.sort(sorter);
    if (suggestions.length > maxAmount) {
      suggestions = suggestions.sublist(0, maxAmount);
    }
    return suggestions;
  }

  @override
  void dispose() {
    if (focusNode == null) {
      textField?.focusNode?.dispose();
    }
    if (controller == null) {
      textField?.controller?.dispose();
    }
    //placeSuggestionController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: _layerLink, child: textField);
  }
}