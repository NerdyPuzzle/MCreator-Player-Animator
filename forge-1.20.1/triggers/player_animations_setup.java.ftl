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

    private static IAnimation registerPlayerAnimations(net.minecraft.client.player.AbstractClientPlayer player) {
	return new ModifierLayer<>();
    }

    @Mod.EventBusSubscriber(bus = Mod.EventBusSubscriber.Bus.MOD)
    public static class ${JavaModName}AnimationMessage {

	Component animation;
	int target;
	boolean override;

	public ${JavaModName}AnimationMessage(Component animation, int target, boolean override) {
		this.animation = animation;
		this.target = target;
		this.override = override;
	}

	public ${JavaModName}AnimationMessage(FriendlyByteBuf buffer) {
		this.animation = buffer.readComponent();
		this.target = buffer.readInt();
		this.override = buffer.readBoolean();
	}

	public static void buffer(${JavaModName}AnimationMessage message, FriendlyByteBuf buffer) {
		buffer.writeComponent(message.animation);
		buffer.writeInt(message.target);
		buffer.writeBoolean(message.override);
	}

	public static void handler(${JavaModName}AnimationMessage message, Supplier<NetworkEvent.Context> contextSupplier) {
		NetworkEvent.Context context = contextSupplier.get();
		context.enqueueWork(() -> {
			Level level = context.getSender().level();
			if (level.getEntity(message.target) != null) {
				Player player = (Player) level.getEntity(message.target);
				setAnimationClientside(player, message.animation.getString(), message.override);
			}
		});
		context.setPacketHandled(true);
	}

	@SubscribeEvent public static void registerMessage(FMLCommonSetupEvent event) {
		${JavaModName}.addNetworkMessage(${JavaModName}AnimationMessage.class, ${JavaModName}AnimationMessage::buffer, ${JavaModName}AnimationMessage::new, ${JavaModName}AnimationMessage::handler);
	}

    }
	
	@OnlyIn(Dist.CLIENT)
	public static void setAnimationClientside(Player player, String anim, boolean override) {
		if (player instanceof net.minecraft.client.player.AbstractClientPlayer player_) { 
			var animation = (ModifierLayer<IAnimation>)PlayerAnimationAccess.getPlayerAssociatedData(player_).get(
				new ResourceLocation("${modid}", "player_animation"));
			if (animation != null && override ? true : !animation.isActive()) {
				animation.setAnimation(new KeyframeAnimationPlayer(PlayerAnimationRegistry.getAnimation(
					new ResourceLocation("${modid}", anim))));
			}
		}
	}