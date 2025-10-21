package ${package}.network;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

@EventBusSubscriber
public record LoadPlayerAnimationMessage(String animationfile) implements CustomPacketPayload {
	public static final Type<LoadPlayerAnimationMessage> TYPE = new Type<>(ResourceLocation.fromNamespaceAndPath(${JavaModName}.MODID, "load_player_animation"));
	public static final StreamCodec<RegistryFriendlyByteBuf, LoadPlayerAnimationMessage> STREAM_CODEC = StreamCodec.of((RegistryFriendlyByteBuf buffer, LoadPlayerAnimationMessage message) -> {
		buffer.writeUtf(message.animationfile);
	}, (RegistryFriendlyByteBuf buffer) -> new LoadPlayerAnimationMessage(buffer.readUtf()));

	@Override
	public Type<LoadPlayerAnimationMessage> type() {
		return TYPE;
	}

	public static void handleData(final LoadPlayerAnimationMessage message, final IPayloadContext context) {
		if (context.flow() == PacketFlow.CLIENTBOUND) {
			context.enqueueWork(() -> {
				JsonObject received = null;
        		try {
        		    received = new Gson().fromJson(message.animationfile, JsonObject.class);
        		} catch (Exception e) {
        		    e.printStackTrace();
        		}
        		${JavaModName}PlayerAnimationAPI.loadAnimationFile(received);
			}).exceptionally(e -> {
				context.connection().disconnect(Component.literal(e.getMessage()));
				return null;
			});
		}
	}

	@SubscribeEvent
	public static void registerMessage(FMLCommonSetupEvent event) {
		${JavaModName}.addNetworkMessage(LoadPlayerAnimationMessage.TYPE, LoadPlayerAnimationMessage.STREAM_CODEC, LoadPlayerAnimationMessage::handleData);
	}
}