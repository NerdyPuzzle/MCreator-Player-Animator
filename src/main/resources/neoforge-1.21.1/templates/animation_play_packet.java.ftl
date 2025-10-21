package ${package}.network;

@EventBusSubscriber
public record PlayPlayerAnimationMessage(int player, String animation, boolean override) implements CustomPacketPayload {
	public static final Type<PlayPlayerAnimationMessage> TYPE = new Type<>(ResourceLocation.fromNamespaceAndPath(${JavaModName}.MODID, "play_player_animation"));
	public static final StreamCodec<RegistryFriendlyByteBuf, PlayPlayerAnimationMessage> STREAM_CODEC = StreamCodec.of((RegistryFriendlyByteBuf buffer, PlayPlayerAnimationMessage message) -> {
		buffer.writeInt(message.player);
		buffer.writeUtf(message.animation);
		buffer.writeBoolean(message.override);
	}, (RegistryFriendlyByteBuf buffer) -> new PlayPlayerAnimationMessage(buffer.readInt(), buffer.readUtf(), buffer.readBoolean()));

	@Override
	public Type<PlayPlayerAnimationMessage> type() {
		return TYPE;
	}

	public static void handleData(final PlayPlayerAnimationMessage message, final IPayloadContext context) {
		if (context.flow() == PacketFlow.CLIENTBOUND) {
			context.enqueueWork(() -> {
				Player player = (Player) context.player().level().getEntity(message.player);
				CompoundTag data = player.getPersistentData();
	            if (message.animation.isEmpty()) {
                    data.putBoolean("ResetPlayerAnimation", true);
                    data.remove("PlayerCurrentAnimation");
                    data.remove("PlayerAnimationProgress");
                } else {
				    data.putString("PlayerCurrentAnimation", message.animation);
				    data.putBoolean("OverrideCurrentAnimation", message.override);
				}
			}).exceptionally(e -> {
				context.connection().disconnect(Component.literal(e.getMessage()));
				return null;
			});
		}
	}

	@SubscribeEvent
	public static void registerMessage(FMLCommonSetupEvent event) {
		${JavaModName}.addNetworkMessage(PlayPlayerAnimationMessage.TYPE, PlayPlayerAnimationMessage.STREAM_CODEC, PlayPlayerAnimationMessage::handleData);
	}
}