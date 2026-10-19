import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// The deck context the router hands the editor.
Widget editorDeckContext(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

CardEditorScreen createEditor(String deckId) =>
    CardEditorScreen.create(deckId: deckId, deckContext: editorDeckContext);

CardEditorScreen editEditor(String cardId) =>
    CardEditorScreen.edit(cardId: cardId, deckContext: editorDeckContext);

/// Front, back, then the tag input once opened.
Finder editorField(int index) => find.byType(EditableText).at(index);

/// A button of the editor's footer, by its label.
Finder editorFooterButton(String label) => find.widgetWithText(MxButton, label);
