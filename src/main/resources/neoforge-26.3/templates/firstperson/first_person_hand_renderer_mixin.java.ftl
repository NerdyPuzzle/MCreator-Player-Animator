package ${package}.mixin;

@Mixin(FirstPersonHandsAndItemsRenderer.class)
public abstract class FirstPersonHandsAndItemsRendererMixin {
    private String master = null;
    private Minecraft mc = Minecraft.getInstance();
    private EntityRenderDispatcher dispatcher = null;

	@Inject(method = "submitHandsWithItems", at = @At("HEAD"), cancellable = true)
	private void renderHandsWithItems(float f, PoseStack poseStack, SubmitNodeCollector collector, PlayerRenderState playerState, FirstPersonHandsAndItemsRenderState state, CallbackInfo ci) {
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return;
		}
		if (!master.equals("${modid}"))
			return;
		if (playerState.avatarRenderState != null) {
		    Player player = (Player) playerState.avatarRenderState.getRenderData(${JavaModName}PlayerAnimationAPI.ClientAttachments.PLAYER);
		    if (player == null)
		        return;
		    if (mc.player != player)
		        return;
		    if (dispatcher == null)
		        dispatcher = mc.getEntityRenderDispatcher();
			CompoundTag playerData = player.getPersistentData();
			// Hack to make animations progress when in first person without first person mode enabled
			if (!playerData.getStringOr("PlayerCurrentAnimation", "").isEmpty() && (!playerData.getBooleanOr("FirstPersonAnimation", false) || playerData.getBooleanOr("ResetPlayerAnimation", false))) {
                AvatarRenderer renderer = (AvatarRenderer) dispatcher.getRenderer((AbstractClientPlayer) player);
                PlayerModel model = (PlayerModel) renderer.getModel();
                AvatarRenderState renderState = (AvatarRenderState) renderer.createRenderState((AbstractClientPlayer) player, f);
                renderState.ageInTicks = player.tickCount + f;
                model.setupAnim(renderState);
			}
			if (playerData.contains("setNullRender")) {
				int ticks = playerData.getIntOr("setNullRender", 0);
				if (ticks <= 0)
					playerData.remove("setNullRender");
				else
					playerData.putInt("setNullRender", ticks - 1);
			}
			if (playerData.getBooleanOr("FirstPersonAnimation", false) && (mc.gui.screen() == null || mc.gui.screen() instanceof ChatScreen))
                ci.cancel();
		}
	}
}