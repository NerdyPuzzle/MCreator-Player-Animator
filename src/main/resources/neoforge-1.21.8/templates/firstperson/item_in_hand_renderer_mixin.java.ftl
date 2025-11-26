package ${package}.mixin;

@Mixin(ItemInHandRenderer.class)
public abstract class ItemInHandRendererMixin {
    private String master = null;
    private Minecraft mc = Minecraft.getInstance();
    private EntityRenderDispatcher dispatcher = null;

	@Inject(method = "renderHandsWithItems", at = @At("HEAD"), cancellable = true)
	private void renderHandsWithItems(float f, PoseStack poseStack, MultiBufferSource.BufferSource bufferSource, LocalPlayer localPlayer, int i, CallbackInfo ci) {
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return;
		}
		if (!master.equals("${modid}"))
			return;
		if (localPlayer instanceof Player player && mc.player == player && mc.screen == null) {
		    if (dispatcher == null)
		        dispatcher = mc.getEntityRenderDispatcher();
			CompoundTag playerData = player.getPersistentData();
			// Hack to make animations progress when in first person without first person mode enabled
			if (!playerData.getStringOr("PlayerCurrentAnimation", "").isEmpty() && (!playerData.getBooleanOr("FirstPersonAnimation", false) || playerData.getBooleanOr("ResetPlayerAnimation", false))) {
                PlayerRenderer renderer = (PlayerRenderer) dispatcher.getRenderer((AbstractClientPlayer) player);
                PlayerModel model = renderer.getModel();
                PlayerRenderState renderState = renderer.createRenderState((AbstractClientPlayer) player, f);
                renderState.ageInTicks = player.tickCount + f;
                model.setupAnim(renderState);
			}
			if (playerData.getBooleanOr("FirstPersonAnimation", false))
                ci.cancel();
		}
	}
}