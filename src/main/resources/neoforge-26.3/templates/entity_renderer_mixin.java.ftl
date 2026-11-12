package ${package}.mixin;

@Mixin(EntityRenderer.class)
public abstract class EntityRendererMixin<T extends Entity> {
	private String master = null;
	private Minecraft mc = Minecraft.getInstance();

    @Inject(method = "affectedByCulling", at = @At("HEAD"), cancellable = true)
    private void affectedByCulling(T player, CallbackInfoReturnable<Boolean> cir) {
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return;
		}
		if (!master.equals("${modid}"))
			return;
	    if (player instanceof Player plr && plr != mc.player && ${JavaModName}PlayerAnimationAPI.active_animations.get(plr) != null)
	        cir.setReturnValue(false);
    }
}