<#include "procedures.java.ftl">
@Mod.EventBusSubscriber(modid = "${modid}", bus = Mod.EventBusSubscriber.Bus.MOD, value = Dist.CLIENT)
public class ${name}Procedure {

    @SubscribeEvent
    public static void onClientSetup(FMLClientSetupEvent event)
    {
        PlayerAnimationFactory.ANIMATION_DATA_FACTORY.registerFactory(
	new ResourceLocation("${modid}", "player_animation"), 
	1000, ${name}Procedure::registerPlayerAnimations);
    }

    private static IAnimation registerPlayerAnimations(AbstractClientPlayer player) {
	return new ModifierLayer<>();
    }

    @Mod.EventBusSubscriber(modid = "${modid}", bus = Mod.EventBusSubscriber.Bus.MOD)
    public static record ${JavaModName}AnimationMessage(Component animation, int target, boolean override) implements CustomPacketPayload {

	public static final ResourceLocation ID = new ResourceLocation(${JavaModName}.MODID, "${registryname}");

	public ${JavaModName}AnimationMessage(FriendlyByteBuf buffer) {
		this(buffer.readComponent(), buffer.readInt(), buffer.readBoolean());
	}

	@Override public void write(final FriendlyByteBuf buffer) {
		buffer.writeComponent(animation);
		buffer.writeInt(target);
		buffer.writeBoolean(override);
	}

	@Override public ResourceLocation id() {
		return ID;
	}

	public static void handleData(final ${JavaModName}AnimationMessage message, final PlayPayloadContext context) {
		if (context.flow() == PacketFlow.CLIENTBOUND) {
			context.workHandler().submitAsync(() -> {
				Level level = Minecraft.getInstance().player.level();
				if (level.getEntity(message.target) != null) {
					Player player = (Player) level.getEntity(message.target);
					if (player instanceof AbstractClientPlayer player_) { 
						var animation = (ModifierLayer<IAnimation>)PlayerAnimationAccess.getPlayerAssociatedData(player_).get(
							new ResourceLocation("${modid}", "player_animation"));
						if (animation != null && (message.override ? true : !animation.isActive())) {
							animation.setAnimation(new KeyframeAnimationPlayer(PlayerAnimationRegistry.getAnimation(
								new ResourceLocation("${modid}", message.animation.getString()))));
						}
					}
				}		
			}).exceptionally(e -> {
				context.packetHandler().disconnect(Component.literal(e.getMessage()));
				return null;
			});
		}
	}

	@SubscribeEvent public static void registerMessage(FMLCommonSetupEvent event) {
		${JavaModName}.addNetworkMessage(${JavaModName}AnimationMessage.ID, ${JavaModName}AnimationMessage::new, ${JavaModName}AnimationMessage::handleData);
	}

    }