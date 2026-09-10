package projects.tanks.clients.fp10.StandaloneLoader
{
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    /**
     * Caixa de erro do loader: painel, mensagem e um botao que fecha o app.
     * Desenhada na mao porque o loader nao linka framework nenhum -- o SWF
     * inteiro tem que caber no que o mxmlc gera sem Flex.
     */
    public class Alert extends Sprite
    {
        private static const WIDTH:Number = 236;
        private static const PADDING:Number = 12;

        public function Alert(message:String, detail:String, buttonLabel:String, onClose:Function)
        {
            super();

            var body:TextField = this.label(message, 12, 0xE8E8E8);
            body.y = PADDING;

            var note:TextField = this.label(detail, 10, 0x8A8A8A);
            note.y = body.y + body.height + 6;

            var button:Sprite = this.makeButton(buttonLabel);
            button.y = note.y + note.height + PADDING;
            button.x = (WIDTH - button.width) / 2;

            var height:Number = button.y + button.height + PADDING;

            this.graphics.beginFill(0x1A1A1A, 0.96);
            this.graphics.lineStyle(1, 0x3C3C3C);
            this.graphics.drawRoundRect(0, 0, WIDTH, height, 6, 6);
            this.graphics.endFill();

            this.addChild(body);
            this.addChild(note);
            this.addChild(button);

            button.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onClose(); });
        }

        private function label(text:String, size:Number, color:uint):TextField
        {
            var field:TextField = new TextField();
            field.autoSize = TextFieldAutoSize.LEFT;
            field.multiline = true;
            field.wordWrap = true;
            field.selectable = false;
            field.width = WIDTH - PADDING * 2;
            field.x = PADDING;
            field.defaultTextFormat = new TextFormat("_sans", size, color, null, null, null, null, null, "center");
            field.text = text;
            return field;
        }

        private function makeButton(text:String):Sprite
        {
            var field:TextField = this.label(text, 11, 0xFFFFFF);
            field.width = 88;
            field.x = 0;

            var button:Sprite = new Sprite();
            button.buttonMode = true;
            button.mouseChildren = false;
            button.graphics.beginFill(0x8C2B2B);
            button.graphics.drawRoundRect(0, 0, 88, field.height + 8, 4, 4);
            button.graphics.endFill();
            field.y = 4;
            button.addChild(field);
            return button;
        }
    }
}
