<#include "procedures.java.ftl">
@EventBusSubscriber(modid = "${modid}", bus = EventBusSubscriber.Bus.MOD, value = Dist.CLIENT)
public class ${name}Procedure {

    @SubscribeEvent
    public static void onClientSetup(FMLClientSetupEvent event) {
        PlayerAnimationAccess.REGISTER_ANIMATION_EVENT.register((player, animationStack) -> {
            ModifierLayer<IAnimation> layer = new ModifierLayer<>();
            animationStack.addAnimLayer(69, layer);
            PlayerAnimationAccess.getPlayerAssociatedData(player).set(ResourceLocation.fromNamespaceAndPath("${modid}", "player_animation"), layer);
        });
    }


    @EventBusSubscriber(modid = "${modid}", bus = EventBusSubscriber.Bus.MOD)
    public static record ${JavaModName}AnimationMessage(String animation, int target, boolean override) implements CustomPacketPayload {

	public static final Type<${JavaModName}AnimationMessage> TYPE = new Type<>(ResourceLocation.fromNamespaceAndPath(${JavaModName}.MODID, "${registryname}"));

	public static final StreamCodec<RegistryFriendlyByteBuf, ${JavaModName}AnimationMessage> STREAM_CODEC = StreamCodec.of(
			(RegistryFriendlyByteBuf buffer, ${JavaModName}AnimationMessage message) -> {
				buffer.writeUtf(message.animation);
				buffer.writeInt(message.target);
				buffer.writeBoolean(message.override);
			},
			(RegistryFriendlyByteBuf buffer) -> new ${JavaModName}AnimationMessage(buffer.readUtf(), buffer.readInt(), buffer.readBoolean())
	);

	@Override public Type<${JavaModName}AnimationMessage> type() {
		return TYPE;
	}

	public static void handleData(final ${JavaModName}AnimationMessage message, final IPayloadContext context) {
		if (context.flow() == PacketFlow.CLIENTBOUND) {
			context.enqueueWork(() -> {
				Level level = context.player().level();
				if (level.getEntity(message.target) != null) {
					Player player = (Player) level.getEntity(message.target);
					setAnimationClientside(player, message.animation, message.override);
				}		
			}).exceptionally(e -> {
				context.connection().disconnect(Component.literal(e.getMessage()));
				return null;
			});
		}
	}

	@SubscribeEvent public static void registerMessage(FMLCommonSetupEvent event) {
		${JavaModName}.addNetworkMessage(${JavaModName}AnimationMessage.TYPE, ${JavaModName}AnimationMessage.STREAM_CODEC, ${JavaModName}AnimationMessage::handleData);
	}

    }
	
	@OnlyIn(Dist.CLIENT)
	public static void setAnimationClientside(Player player, String anim, boolean override) {
		if (player instanceof net.minecraft.client.player.AbstractClientPlayer player_) { 
			var animation = (ModifierLayer<IAnimation>) PlayerAnimationAccess.getPlayerAssociatedData(player_).get(ResourceLocation.fromNamespaceAndPath("${modid}", "player_animation"));
			if (animation != null && override ? true : !animation.isActive()) {
				animation.replaceAnimationWithFade(AbstractFadeModifier.functionalFadeIn(20, (modelName, type, value) -> value),
					PlayerAnimationRegistry.getAnimation(ResourceLocation.fromNamespaceAndPath("${modid}", anim)).playAnimation()
					.setFirstPersonMode(FirstPersonMode.THIRD_PERSON_MODEL)
					.setFirstPersonConfiguration(new FirstPersonConfiguration().setShowRightArm(true).setShowLeftItem(false))
				);
			}
		}
	}