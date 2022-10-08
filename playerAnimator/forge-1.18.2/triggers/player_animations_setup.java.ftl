<#include "procedures.java.ftl">
@Mod.EventBusSubscriber(modid = "${modid}", bus = Mod.EventBusSubscriber.Bus.MOD) public class ${name}Procedure {
        public static final Map<AbstractClientPlayer, ModifierLayer<IAnimation>> animationData = new IdentityHashMap<>();


    @SubscribeEvent
    public static void onClientSetup(FMLClientSetupEvent event)
    {
        PlayerAnimationAccess.REGISTER_ANIMATION_EVENT.register(SetupAnimationsProcedure::registerPlayerAnimation);
    }

    private static void registerPlayerAnimation(AbstractClientPlayer player, AnimationStack stack) {
        var layer = new ModifierLayer<>();
        stack.addAnimLayer(1000, layer); //Register the layer with a priority

        SetupAnimationsProcedure.animationData.put(player, layer);

    }
