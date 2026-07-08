package ${package}.mixin;

import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(Camera.class)
public interface CameraAccessor {
	@Accessor
	public void setDetached(boolean value);
}