package projects.tanks.clients.fp10.StandaloneLoader
{
    /**
     * Textos do loader. So existem mensagens de erro: tudo que o jogador ve
     * depois que o Prelauncher sobe vem do proprio jogo, e nao daqui.
     *
     * O locale chega pela query string do descritor (locale=pt_BR). Sem
     * correspondencia, cai no ingles.
     */
    public class LocalizedTexts
    {
        private static const TEXTS:Object = {
            "pt": {
                "loadFailed": "Nao foi possivel carregar o LeTanki.\nVerifique sua conexao e tente de novo.",
                "details": "Endereco: %URL%",
                "quit": "Sair"
            },
            "en": {
                "loadFailed": "Could not load LeTanki.\nCheck your connection and try again.",
                "details": "Address: %URL%",
                "quit": "Quit"
            },
            "ru": {
                "loadFailed": "\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c LeTanki.\n\u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435 \u0438 \u043f\u043e\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 \u0441\u043d\u043e\u0432\u0430.",
                "details": "\u0410\u0434\u0440\u0435\u0441: %URL%",
                "quit": "\u0412\u044b\u0445\u043e\u0434"
            }
        };

        private var strings:Object;

        public function LocalizedTexts(locale:String)
        {
            // pt_BR, pt-BR ou pt caem todos em "pt".
            var language:String = locale == null ? "en" : locale.split(/[_-]/)[0].toLowerCase();
            this.strings = TEXTS[language] || TEXTS["en"];
        }

        public function get(key:String):String
        {
            var text:String = this.strings[key];
            return text == null ? key : text;
        }

        public function format(key:String, token:String, value:String):String
        {
            return this.get(key).split(token).join(value);
        }
    }
}
