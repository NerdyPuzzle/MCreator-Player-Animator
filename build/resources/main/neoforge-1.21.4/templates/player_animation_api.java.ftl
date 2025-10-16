package ${package};

import org.apache.commons.lang3.tuple.Pair;

import com.google.gson.JsonObject;
import com.google.gson.JsonElement;
import com.google.gson.JsonArray;

public class ${JavaModName}PlayerAnimationAPI {
	public static final Map<String, PlayerAnimation> animations = new Object2ObjectOpenHashMap<>();
	public static final Map<Player, PlayerAnimation> active_animations = new Object2ObjectOpenHashMap<>();
	public static boolean initialized = false;

	public static void loadAnimationFile(JsonObject file) {
		JsonObject animationsObject = file.get("animations").getAsJsonObject();
		for (int i = 0; i < animationsObject.size(); i++) {
			String animationName = animationsObject.keySet().stream().toList().get(i);
			JsonObject animationObject = animationsObject.get(animationName).getAsJsonObject();
			PlayerAnimation animation = new PlayerAnimation(animationObject);
			animations.put(animationName, animation);
		}
	}

	public static class PlayerAnimation {
		public final float length;
		public boolean loop = false;
		public boolean hold_on_last_frame = false;
		public final Map<String, PlayerBone> bones;

		public PlayerAnimation(JsonObject animation) {
		    if (animation.has("animation_length")
			    this.length = animation.get("animation_length").getAsFloat();
			else
			    this.length = 0;
			if (animation.has("loop")) {
				JsonElement loopType = animation.get("loop");
				if (loopType.isJsonPrimitive() && loopType.getAsJsonPrimitive().isBoolean())
					this.loop = loopType.getAsBoolean();
				else if (loopType.isJsonPrimitive())
					this.hold_on_last_frame = true;
			}
			this.bones = new HashMap<>();
			if (animation.has("bones")) {
				JsonObject bonesObj = animation.getAsJsonObject("bones");
				for (String boneName : bonesObj.keySet()) {
					this.bones.put(boneName, new PlayerBone(bonesObj.getAsJsonObject(boneName)));
				}
			}
		}
	}

	public static class PlayerBone {
		public final List<Pair<Float, Vec3>> rotations;
		public final List<Pair<Float, Vec3>> positions;
		public final List<Pair<Float, Vec3>> scales;

		public PlayerBone(JsonObject bone) {
			this.rotations = parseTransform(bone, "rotation");
			this.positions = parseTransform(bone, "position");
			this.scales = parseTransform(bone, "scale");
		}

		private List<Pair<Float, Vec3>> parseTransform(JsonObject bone, String key) {
			List<Pair<Float, Vec3>> result = new ArrayList<>();
			if (!bone.has(key)) {
				return result;
			}
			JsonElement element = bone.get(key);
			if (element.isJsonArray()) {
				// Single value: [x, y, z] at time 0
				result.add(Pair.of(0f, parseVec3(element.getAsJsonArray())));
			} else if (element.isJsonPrimitive()) {
				// Single number (for scale): expand to [n, n, n] at time 0
				float value = element.getAsFloat();
				result.add(Pair.of(0f, new Vec3(value, value, value)));
			} else if (element.isJsonObject()) {
				// Keyframe object: { "0.0": [x, y, z], "0.5": [x, y, z] }
				JsonObject keyframes = element.getAsJsonObject();
				for (String timeStr : keyframes.keySet()) {
					float time = Float.parseFloat(timeStr);
					JsonElement frameValue = keyframes.get(timeStr);
					if (frameValue.isJsonArray()) {
						result.add(Pair.of(time, parseVec3(frameValue.getAsJsonArray())));
					} else if (frameValue.isJsonPrimitive()) {
						float value = frameValue.getAsFloat();
						result.add(Pair.of(time, new Vec3(value, value, value)));
					}
				}
			}
			return result;
		}

		private Vec3 parseVec3(JsonArray array) {
			return new Vec3(array.get(0).getAsFloat(), array.get(1).getAsFloat(), array.get(2).getAsFloat());
		}

		public static Vec3 interpolate(List<Pair<Float, Vec3>> keyframes, float time) {
			if (keyframes.isEmpty())
				return null;
			if (keyframes.size() == 1)
				return keyframes.get(0).getRight();
			// Find the last keyframe that has passed
			Pair<Float, Vec3> lastKeyframe = null;
			for (Pair<Float, Vec3> keyframe : keyframes) {
				if (time >= keyframe.getLeft()) {
					lastKeyframe = keyframe;
				} else {
					break;
				}
			}
			// If time is before first keyframe, return null
			if (lastKeyframe == null)
				return null;
			// Find the next keyframe
			Pair<Float, Vec3> nextKeyframe = null;
			for (Pair<Float, Vec3> keyframe : keyframes) {
				if (keyframe.getLeft() > time) {
					nextKeyframe = keyframe;
					break;
				}
			}
			// If there's no next keyframe, hold at the last keyframe (no interpolation)
			if (nextKeyframe == null)
				return lastKeyframe.getRight();
			// Linear interpolation between the two keyframes
			float t1 = lastKeyframe.getLeft();
			float t2 = nextKeyframe.getLeft();
			Vec3 v1 = lastKeyframe.getRight();
			Vec3 v2 = nextKeyframe.getRight();
			if (t1 == t2)
				return v1;
			float alpha = (time - t1) / (t2 - t1);
			return new Vec3(lerp(v1.x, v2.x, alpha), lerp(v1.y, v2.y, alpha), lerp(v1.z, v2.z, alpha));
		}

		private static double lerp(double a, double b, float t) {
			return a + (b - a) * t;
		}
	}

	@EventBusSubscriber
	private static class AnimationLoader {
		@SubscribeEvent
		public static void loadAnimations(PlayerEvent.PlayerLoggedInEvent event) {
			if (!${JavaModName}PlayerAnimationAPI.initialized) {
				if (event.getEntity() instanceof ServerPlayer player) {
					${JavaModName}PlayerAnimationAPI.initialized = true;
					ServerLevel level = (ServerLevel) player.level();
					class Output implements PackResources.ResourceOutput {
						private List<JsonObject> jsonObjects;
						private PackResources packResources;

						public Output(List<JsonObject> jsonObjects) {
							this.jsonObjects = jsonObjects;
						}

						public void setPackResources(PackResources packResources) {
							this.packResources = packResources;
						}

						@Override
						public void accept(ResourceLocation resourceLocation, IoSupplier<InputStream> ioSupplier) {
							try {
								JsonObject jsonObject = new com.google.gson.Gson()
										.fromJson(new java.io.BufferedReader(new java.io.InputStreamReader(ioSupplier.get(), java.nio.charset.StandardCharsets.UTF_8)).lines().collect(Collectors.joining("\n")), JsonObject.class);
								this.jsonObjects.add(jsonObject);
							} catch (Exception e) {
							}
						}
					}
					List<JsonObject> jsons = new ArrayList<>();
					Output output = new Output(jsons);
					ResourceManager rm = level.getServer().getResourceManager();
					rm.listPacks().forEach(resource -> {
						for (String namespace : resource.getNamespaces(PackType.SERVER_DATA)) {
                        	output.setPackResources(resource);
                        	resource.listResources(PackType.SERVER_DATA, namespace, "bedrock_animations", output);
                        }
					});
					sendAnimationsInBatches(player, jsons);
				}
			}
		}

		private static void sendAnimationsInBatches(ServerPlayer player, List<JsonObject> jsons) {
            final int MAX_CHARS = 30000; // Safety buffer below 32767
            final int ANIMATIONS_WRAPPER_OVERHEAD = "{\"animations\":{}}".length();

            JsonObject currentBatch = new JsonObject();
            JsonObject animationsObject = new JsonObject();
            currentBatch.add("animations", animationsObject);

            int currentSize = ANIMATIONS_WRAPPER_OVERHEAD;
            int animationCount = 0;

            for (JsonObject animationJson : jsons) {
                // Extract the animations from each JSON
                JsonObject sourceAnimations = animationJson.getAsJsonObject("animations");

                if (sourceAnimations != null) {
                    for (Map.Entry<String, JsonElement> entry : sourceAnimations.entrySet()) {
                        String animationName = entry.getKey();
                        JsonElement animationData = entry.getValue();

                        // Calculate size this animation would add
                        String animationString = "\"" + animationName + "\":" + animationData.toString();
                        int animationSize = animationString.length() + 1; // +1 for comma

                        // Check if adding this would exceed limit
                        if (currentSize + animationSize > MAX_CHARS && animationCount > 0) {
                            PacketDistributor.sendToPlayer(player,
                                new LoadPlayerAnimationMessage(currentBatch.toString()));

                            currentBatch = new JsonObject();
                            animationsObject = new JsonObject();
                            currentBatch.add("animations", animationsObject);
                            currentSize = ANIMATIONS_WRAPPER_OVERHEAD;
                            animationCount = 0;
                        }

                        animationsObject.add(animationName, animationData);
                        currentSize += animationSize;
                        animationCount++;
                    }
                }
            }

            // Send final batch if it has any animations
            if (animationCount > 0) {
                PacketDistributor.sendToPlayer(player,
                    new LoadPlayerAnimationMessage(currentBatch.toString()));
            }
        }
	}

	@EventBusSubscriber(value = Dist.CLIENT, bus = EventBusSubscriber.Bus.MOD)
	public static class ClientAttachments {
		public static final ContextKey<Player> PLAYER = new ContextKey<>(ResourceLocation.parse("c:player_attachment"));

		@SubscribeEvent
		public static void register(RegisterRenderStateModifiersEvent event) {
		    event.registerEntityModifier(PlayerRenderer.class, (entity, state) -> state.setRenderData(PLAYER, (Player) entity));
		}
	}
}