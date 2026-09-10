package projects.tanks.clients.fp10.StandaloneLoader
{
    import flash.desktop.NativeApplication;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.Screen;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.geom.Rectangle;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.system.ApplicationDomain;
    import flash.system.LoaderContext;
    import flash.utils.ByteArray;

    /**
     * O que o LeTanki.exe abre. O trabalho todo e: mostrar o logo, baixar o
     * Prelauncher do endereco que veio na query string e entregar a tela para
     * ele. Dali em diante nada mais aqui roda -- o jogo inteiro vem do CDN.
     *
     * Os enderecos chegam pelo <content> do application.xml.
     *
     * O SWF nao e carregado por Loader.load: conteudo baixado de http cai no
     * sandbox remoto e nao pode encostar no Stage, que e nosso -- da
     * SecurityError #2070 na hora que o Prelauncher tenta montar a tela. Por
     * isso os bytes vem por URLLoader e sao executados com loadBytes e
     * allowLoadBytesCodeExecution, o que roda tudo no sandbox da aplicacao.
     *
     * E de la que o Prelauncher enxerga stage.loaderInfo.parameters, que sao os
     * parametros do descritor -- swf, config, resources, balancer, prefix e
     * locale. Nao ha nada a repassar na mao.
     */
    [SWF(width="256", height="256", frameRate="40", backgroundColor="#000000")]
    public class StandaloneLoader extends Sprite
    {
        [Embed(source="/assets/logo.png")]
        private static const LOGO:Class;

        private static const DEFAULT_PRELAUNCHER:String = "https://res.letanki.com/Prelauncher.swf";

        private var texts:LocalizedTexts;
        private var logo:Bitmap;
        private var bytes:URLLoader;
        private var loader:Loader;
        private var url:String;

        public function StandaloneLoader()
        {
            super();
            if (stage) {
                this.start();
            } else {
                this.addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
            }
        }

        private function onAddedToStage(event:Event):void
        {
            this.removeEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
            this.start();
        }

        private function start():void
        {
            // NO_SCALE porque quem manda no tamanho e o Prelauncher: ele
            // redimensiona a janela quando assume.
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;

            // Sem isso, qualquer excecao nao tratada vira janela preta muda --
            // o AIR nao tem console para onde reclamar.
            loaderInfo.uncaughtErrorEvents.addEventListener(
                UncaughtErrorEvent.UNCAUGHT_ERROR, this.onUncaughtError);

            var parameters:Object = loaderInfo.parameters || {};
            this.texts = new LocalizedTexts(parameters["locale"]);

            this.showLogo();
            this.centerWindow();

            this.url = parameters["prelauncher"] || DEFAULT_PRELAUNCHER;
            this.bytes = new URLLoader();
            this.bytes.dataFormat = URLLoaderDataFormat.BINARY;
            this.bytes.addEventListener(Event.COMPLETE, this.onBytesReady);
            this.bytes.addEventListener(IOErrorEvent.IO_ERROR, this.onPrelauncherFailed);
            this.bytes.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onPrelauncherFailed);
            this.bytes.load(new URLRequest(this.url));
        }

        private function onBytesReady(event:Event):void
        {
            var context:LoaderContext = new LoaderContext();
            // O que tira o Prelauncher do sandbox remoto.
            context.allowLoadBytesCodeExecution = true;
            // Dominio filho: as classes dele nao colidem com as nossas.
            context.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);

            this.loader = new Loader();
            this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onPrelauncherReady);
            this.loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.onPrelauncherFailed);
            this.loader.loadBytes(ByteArray(this.bytes.data), context);
        }

        private function showLogo():void
        {
            // Sem o framework Flex linkado, o mxmlc gera o [Embed] de imagem
            // como BitmapData; com ele, como Bitmap. Aceita os dois.
            var asset:Object = new LOGO();
            this.logo = asset is Bitmap ? Bitmap(asset) : new Bitmap(BitmapData(asset));
            this.logo.smoothing = true;
            // O PNG e maior que o palco; encolhe mantendo proporcao.
            var scale:Number = Math.min(stage.stageWidth / this.logo.width, stage.stageHeight / this.logo.height);
            this.logo.scaleX = this.logo.scaleY = scale;
            this.logo.x = (stage.stageWidth - this.logo.width) / 2;
            this.logo.y = (stage.stageHeight - this.logo.height) / 2;
            this.addChild(this.logo);
        }

        private function centerWindow():void
        {
            var window:Object = stage.nativeWindow;
            if (window == null) {
                return;
            }
            var bounds:Rectangle = Screen.mainScreen.visibleBounds;
            window.x = bounds.x + (bounds.width - window.width) / 2;
            window.y = bounds.y + (bounds.height - window.height) / 2;
        }

        private function onPrelauncherReady(event:Event):void
        {
            if (this.logo != null && this.contains(this.logo)) {
                this.removeChild(this.logo);
                this.logo = null;
            }
            this.addChild(this.loader);
        }

        private function onPrelauncherFailed(event:Event):void
        {
            if (this.logo != null && this.contains(this.logo)) {
                this.logo.alpha = 0.25;
            }

            this.showAlert(this.texts.get("loadFailed"),
                this.texts.format("details", "%URL%", this.url));
        }

        private function showAlert(message:String, detail:String):void
        {
            var alert:Alert = new Alert(message, detail, this.texts.get("quit"), this.quit);
            alert.x = (stage.stageWidth - alert.width) / 2;
            alert.y = (stage.stageHeight - alert.height) / 2;
            this.addChild(alert);
        }

        private function onUncaughtError(event:UncaughtErrorEvent):void
        {
            event.preventDefault();
            var error:Object = event.error;
            this.showAlert(this.texts.get("loadFailed"),
                error is Error ? Error(error).message : String(error));
        }

        private function quit():void
        {
            NativeApplication.nativeApplication.exit();
        }
    }
}
