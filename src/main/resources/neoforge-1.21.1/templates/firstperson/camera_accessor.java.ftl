package ${package}.mixin;

@Mixin(Camera.class)
public interface CameraAccessor {
	@Accessor
	public void setDetached(boolean value);
}