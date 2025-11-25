package ${package};

import com.google.gson.JsonObject;
import com.google.gson.JsonElement;
import com.google.gson.JsonArray;
import com.google.gson.JsonPrimitive;
import com.google.gson.Gson;

import java.nio.file.Files;
import java.nio.file.Path;

public class ${JavaModName}PlayerAnimationAPI {
	public static final Map<String, PlayerAnimation> animations = new Object2ObjectOpenHashMap<>();
	public static final Map<Player, PlayerAnimation> active_animations = new Object2ObjectOpenHashMap<>();

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
		public final Map<Float, String> soundEffects;

		public PlayerAnimation(JsonObject animation) {
			if (animation.has("animation_length"))
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
			this.soundEffects = new HashMap<>();
			if (animation.has("sound_effects")) {
				JsonObject soundEffectsObj = animation.getAsJsonObject("sound_effects");
				for (Map.Entry<String, JsonElement> entry : soundEffectsObj.entrySet()) {
					try {
						float time = Float.parseFloat(entry.getKey());
						JsonObject soundData = entry.getValue().getAsJsonObject();
						if (soundData.has("effect")) {
							String soundId = soundData.get("effect").getAsString();
							soundEffects.put(time, soundId);
						}
					} catch (NumberFormatException e) {
						// Skip invalid time format
						e.printStackTrace();
					}
				}
			}
		}
	}

	public static class PlayerBone {
		public final List<Keyframe> rotations;
		public final List<Keyframe> positions;
		public final List<Keyframe> scales;

		public PlayerBone(JsonObject bone) {
			this.rotations = parseTransform(bone, "rotation");
			this.positions = parseTransform(bone, "position");
			this.scales = parseTransform(bone, "scale");
		}

		public static class Keyframe {
			public final float time;
			public final KeyframeValue value;
			public final KeyframeValue pre;
			public final KeyframeValue post;
			public final boolean catmullrom;

			public Keyframe(float time, KeyframeValue value, KeyframeValue pre, KeyframeValue post, boolean catmullrom) {
				this.time = time;
				this.value = value;
				this.pre = pre != null ? pre : value;
				this.post = post != null ? post : value;
				this.catmullrom = catmullrom;
			}
		}

		public static class KeyframeValue {
			public final Vec3 vector;
			public final String molang;

			public KeyframeValue(Vec3 vector) {
				this.vector = vector;
				this.molang = null;
			}

			public KeyframeValue(String molang) {
				this.molang = molang;
				this.vector = null;
			}

			public boolean isMolang() {
				return molang != null;
			}
		}

		private List<Keyframe> parseTransform(JsonObject bone, String key) {
			List<Keyframe> result = new ArrayList<>();
			if (!bone.has(key)) {
				return result;
			}
			JsonElement element = bone.get(key);

			if (element.isJsonArray()) {
				result.add(new Keyframe(0f, parseValue(element), null, null, false));
			} else if (element.isJsonPrimitive()) {
				result.add(new Keyframe(0f, parseValue(element), null, null, false));
			} else if (element.isJsonObject()) {
				JsonObject keyframes = element.getAsJsonObject();
				for (String timeStr : keyframes.keySet()) {
					float time = Float.parseFloat(timeStr);
					JsonElement frameValue = keyframes.get(timeStr);

					if (frameValue.isJsonArray() || frameValue.isJsonPrimitive()) {
						result.add(new Keyframe(time, parseValue(frameValue), null, null, false));
					} else if (frameValue.isJsonObject()) {
						JsonObject frameObj = frameValue.getAsJsonObject();
						KeyframeValue value = frameObj.has("post") ? parseValue(frameObj.get("post")) : parseValue(frameValue);
						KeyframeValue pre = frameObj.has("pre") ? parseValue(frameObj.get("pre")) : null;
						KeyframeValue post = frameObj.has("post") ? parseValue(frameObj.get("post")) : null;
						boolean catmullrom = frameObj.has("lerp_mode") && frameObj.get("lerp_mode").getAsString().equalsIgnoreCase("catmullrom");
						result.add(new Keyframe(time, value, pre, post, catmullrom));
					}
				}
			}
			return result;
		}

		private KeyframeValue parseValue(JsonElement element) {
			if (element.isJsonArray()) {
				JsonArray array = element.getAsJsonArray();
				boolean hasMolang = false;
				StringBuilder molangArray = new StringBuilder("[");

				for (int i = 0; i < array.size(); i++) {
					if (i > 0) molangArray.append(",");
					JsonElement elem = array.get(i);
					if (elem.isJsonPrimitive()) {
						JsonPrimitive prim = elem.getAsJsonPrimitive();
						if (prim.isString()) {
							hasMolang = true;
							molangArray.append(prim.getAsString());
						} else {
							molangArray.append(prim.getAsFloat());
						}
					}
				}
				molangArray.append("]");

				if (hasMolang) return new KeyframeValue(molangArray.toString());

				float x = array.size() > 0 && array.get(0).isJsonPrimitive() ? array.get(0).getAsFloat() : 0;
				float y = array.size() > 1 && array.get(1).isJsonPrimitive() ? array.get(1).getAsFloat() : 0;
				float z = array.size() > 2 && array.get(2).isJsonPrimitive() ? array.get(2).getAsFloat() : 0;
				return new KeyframeValue(new Vec3(x, y, z));
			}

			if (element.isJsonPrimitive()) {
				JsonPrimitive prim = element.getAsJsonPrimitive();
				if (prim.isString()) return new KeyframeValue(prim.getAsString());
				float value = prim.getAsFloat();
				return new KeyframeValue(new Vec3(value, value, value));
			}

			return new KeyframeValue(Vec3.ZERO);
		}

		public static Vec3 interpolate(List<Keyframe> keyframes, float time) {
			if (keyframes.isEmpty()) return null;
			if (keyframes.size() == 1) {
				Keyframe kf = keyframes.get(0);
				return kf.value.isMolang() ? evalMolang(kf.value.molang, time) : kf.value.vector;
			}

			Keyframe lastKf = null;
			Keyframe nextKf = null;
			int lastIdx = -1;

			for (int i = 0; i < keyframes.size(); i++) {
				Keyframe kf = keyframes.get(i);
				if (time >= kf.time) {
					lastKf = kf;
					lastIdx = i;
				}
				if (time < kf.time) {
					nextKf = kf;
					break;
				}
			}

			if (lastKf == null) return null;
			Vec3 postVec = lastKf.post.isMolang() ? evalMolang(lastKf.post.molang, time) : lastKf.post.vector;
			if (nextKf == null) return postVec;

			float t1 = lastKf.time;
			float t2_ = nextKf.time;
			if (t1 == t2_) return postVec;

			float alpha = (time - t1) / (t2_ - t1);
			Vec3 v1 = postVec;
			Vec3 v2 = nextKf.pre.isMolang() ? evalMolang(nextKf.pre.molang, time) : nextKf.pre.vector;

			if (lastKf.catmullrom) {
				Vec3 p0 = v1, p1 = v1, p2 = v2, p3 = v2;
				if (lastIdx > 0) {
					KeyframeValue kv = keyframes.get(lastIdx - 1).post;
					p0 = kv.isMolang() ? evalMolang(kv.molang, time) : kv.vector;
				}
				if (lastIdx + 1 < keyframes.size() - 1) {
					KeyframeValue kv = keyframes.get(lastIdx + 2).pre;
					p3 = kv.isMolang() ? evalMolang(kv.molang, time) : kv.vector;
				}

				float t = alpha, t2 = t * t, t3 = t2 * t;
				return new Vec3(
					0.5 * ((2 * p1.x) + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
					0.5 * ((2 * p1.y) + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3),
					0.5 * ((2 * p1.z) + (-p0.z + p2.z) * t + (2 * p0.z - 5 * p1.z + 4 * p2.z - p3.z) * t2 + (-p0.z + 3 * p1.z - 3 * p2.z + p3.z) * t3)
				);
			}

			return new Vec3(v1.x + (v2.x - v1.x) * alpha, v1.y + (v2.y - v1.y) * alpha, v1.z + (v2.z - v1.z) * alpha);
		}

		private static Vec3 evalMolang(String expr, float time) {
			expr = expr.replace("query.anim_time", String.valueOf(time));
			try {
				if (expr.trim().startsWith("[") && expr.trim().endsWith("]")) {
					String inner = expr.trim().substring(1, expr.trim().length() - 1);
					String[] parts = inner.split(",");
					return new Vec3(
						parts.length > 0 ? evalFloat(parts[0].trim(), time) : 0,
						parts.length > 1 ? evalFloat(parts[1].trim(), time) : 0,
						parts.length > 2 ? evalFloat(parts[2].trim(), time) : 0
					);
				}
				float val = evalFloat(expr, time);
				return new Vec3(val, val, val);
			} catch (Exception e) {
				return Vec3.ZERO;
			}
		}

		private static float evalFloat(String expr, float time) {
			expr = expr.replace("query.anim_time", String.valueOf(time)).trim().replace(" ", "");
			String lower = expr.toLowerCase();

			if (lower.startsWith("math.sin(") && lower.endsWith(")")) {
				return (float) Math.sin(Math.toRadians(evalFloat(expr.substring(9, expr.length() - 1), time)));
			}
			if (lower.startsWith("math.cos(") && lower.endsWith(")")) {
				return (float) Math.cos(Math.toRadians(evalFloat(expr.substring(9, expr.length() - 1), time)));
			}

			int depth = 0;
			for (int i = expr.length() - 1; i >= 0; i--) {
				char c = expr.charAt(i);
				if (c == ')') depth++;
				else if (c == '(') depth--;
				else if (depth == 0) {
					if (c == '+' || (c == '-' && i > 0)) {
						return c == '+' ? evalFloat(expr.substring(0, i), time) + evalFloat(expr.substring(i + 1), time)
										: evalFloat(expr.substring(0, i), time) - evalFloat(expr.substring(i + 1), time);
					}
				}
			}

			depth = 0;
			for (int i = expr.length() - 1; i >= 0; i--) {
				char c = expr.charAt(i);
				if (c == ')') depth++;
				else if (c == '(') depth--;
				else if (depth == 0 && (c == '*' || c == '/')) {
					return c == '*' ? evalFloat(expr.substring(0, i), time) * evalFloat(expr.substring(i + 1), time)
									: evalFloat(expr.substring(0, i), time) / evalFloat(expr.substring(i + 1), time);
				}
			}

			if (expr.startsWith("-")) return -evalFloat(expr.substring(1), time);
			return Float.parseFloat(expr);
		}
	}

	@EventBusSubscriber(Dist.CLIENT)
	public static class AnimationLoader {
		@SubscribeEvent
		public static void onClientSetup(FMLClientSetupEvent event) {
			event.enqueueWork(() -> {
				loadClientSideAnimations();
			});
		}

		private static void loadClientSideAnimations() {
			List<JsonObject> jsons = new ArrayList<>();
			List<String> namespaces = new ArrayList<>();
			ModList.get().forEachModFile(modFile -> {
				String modId = modFile.getModInfos().get(0).getModId();
				Path rootPath = modFile.findResource("data");
				if (rootPath == null || !Files.exists(rootPath)) {
					return;
				}
				try {
					Path animationsPath = rootPath.resolve(modId).resolve("bedrock_animations");
					if (Files.exists(animationsPath) && Files.isDirectory(animationsPath)) {
						try (Stream<Path> paths = Files.walk(animationsPath)) {
							paths.filter(Files::isRegularFile)
								 .filter(path -> path.toString().endsWith(".json"))
								 .forEach(animationFile -> {
									 try {
										 String content = Files.readString(animationFile, StandardCharsets.UTF_8);
										 JsonObject jsonObject = new Gson().fromJson(content, JsonObject.class);
										 jsons.add(jsonObject);
										 namespaces.add(modId);
									 } catch (Exception e) {
										 System.err.println("Failed to load animation file: " + animationFile + " - " + e.getMessage());
									 }
								 });
						}
					}
				} catch (Exception e) {
					System.err.println("Failed to process animations for mod: " + modId + " - " + e.getMessage());
				}
			});
			if (!jsons.isEmpty()) {
				loadAnimations(jsons, namespaces);
			}
		}

		private static void loadAnimations(List<JsonObject> jsons, List<String> namespaces) {
			int namespaceIndex = 0;
			for (JsonObject animationJson : jsons) {
				JsonObject sourceAnimations = animationJson.getAsJsonObject("animations");
				if (sourceAnimations != null) {
					JsonObject namespacedAnimations = new JsonObject();
					JsonObject animationsWrapper = new JsonObject();
					for (Map.Entry<String, JsonElement> entry : sourceAnimations.entrySet()) {
						String animationName = namespaces.get(namespaceIndex) + ":" + entry.getKey();
						namespacedAnimations.add(animationName, entry.getValue());
					}
					animationsWrapper.add("animations", namespacedAnimations);
					${JavaModName}PlayerAnimationAPI.loadAnimationFile(animationsWrapper);
				}
				namespaceIndex++;
			}
		}
	}

	@EventBusSubscriber(value = Dist.CLIENT)
	public static class ClientAttachments {
		public static final ContextKey<Player> PLAYER = new ContextKey<>(ResourceLocation.parse("c:player_attachment"));

		@SubscribeEvent
		public static void register(RegisterRenderStateModifiersEvent event) {
			event.registerEntityModifier(PlayerRenderer.class, (entity, state) -> state.setRenderData(PLAYER, (Player) entity));
		}
	}
}