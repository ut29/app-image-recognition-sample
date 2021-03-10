import torch
import coremltools as ct
import torchvision.models as models
import urllib

# 1. Loading pre-trained model
model = models.mobilenet_v2(pretrained=True)

model.eval()

# 2. Loading class names
label_url = 'https://storage.googleapis.com/download.tensorflow.org/data/ImageNetLabels.txt'
class_labels = urllib.request.urlopen(label_url).read().decode("utf-8").splitlines()
class_labels = class_labels[1:] # remove the first class which is background
assert len(class_labels) == 1000

dummy_input = torch.FloatTensor(1, 3, 224, 224)
traced_model = torch.jit.trace(model, dummy_input)


# 3. Pre-processing
# corresponds to transforms.ToTensor()
# and transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
# See https://pytorch.org/hub/pytorch_vision_mobilenet_v2/ in detail.
scale = 1.0 / (0.226 * 255.0)
red_scale = 1.0 / (0.229 * 255.0)
green_scale = 1.0 / (0.224 * 255.0)
blue_scale = 1.0 / (0.225 * 255.0)

red_bias= -(0.485 * 255.0) * red_scale
green_bias= -(0.456 * 255.0) * green_scale
blue_bias = -(0.406 * 255.0) * blue_scale

# 4. Conversion
mlmodel = ct.convert(traced_model,
                    inputs=[ct.ImageType(name="image", bias=[red_bias, green_bias, blue_bias], scale=scale, shape=dummy_input.shape)],
                    classifier_config = ct.ClassifierConfig(class_labels),
                    )
mlmodel.save('./MyModel.mlmodel')