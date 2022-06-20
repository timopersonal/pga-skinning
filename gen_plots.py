import glob
import os
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick

# Map model identifiers to human-readable name.
model_to_name = {
    'candywrap': 'Candy-wrapper Test',
    'jointbulge': 'Joint-bulge Test',
    'cesiumman': 'Cesium Man',
}

# Map algorithm identifiers to human-readable name.
technique_to_name = {
    'dqs': 'Dual Quaternion Skinning',
    'pga': 'PGA Skinning'
}

# Map algorithms identifiers to color identifier for matplotlib
technique_to_color = {
    'dqs': 'red',
    'pga': 'green'
}


def split_data(file):
    """
    Split the data in the data file, and remove headers.
    """
    parts = filter(lambda x: x != "", file.removesuffix(
        os.linesep).split(os.linesep*3))
    return list(map(lambda x: map(float, x.split(os.linesep)[1:]), parts))


data_map = dict()

# Open all stats files.
for filename in glob.glob('stats_*_*.txt'):
    technique, model = filename.removesuffix('.txt').split('_')[1:]
    filedata = split_data(open(filename).read())
    if data_map.get(model) is None:
        data_map[model] = dict()
    data_map[model][technique] = list(map(list, filedata))

# Plot the data
fig, axes = plt.subplots(
    len(data_map), 2, squeeze=False, figsize=(8.27, 11.69))
for i, (model_name, model_data) in enumerate(data_map.items()):
    for technique, data in model_data.items():
        volume_diff, detail_diff = data

        # Retrieve appropriate label and color for this technique
        label = technique_to_name.get(
            technique, 'Unknown technique')
        color = technique_to_color.get(technique, None)

        # Plot the volume differences
        axes[i, 0].plot([x * 100 for x in volume_diff],
                        label=label, color=color)
        axes[i, 0].yaxis.set_major_formatter(mtick.PercentFormatter())
        axes[i, 0].set_xlabel('$n$-th frame')
        axes[i, 0].set_ylabel('Preserved Volume')

        # Plot the detail differences
        axes[i, 1].plot(detail_diff, label=label, color=color)
        axes[i, 1].set_xlabel('$n$-th frame')
        axes[i, 1].set_ylabel('Total difference in local detail')

# Set titles of columns and rows
# https://stackoverflow.com/a/25814386
pad = 5
for ax, col in zip(axes[0], ["Volume Preservation", "Local Detail Preservation"]):
    ax.annotate(col, xy=(0.5, 1), xytext=(0, pad),
                xycoords='axes fraction', textcoords='offset points',
                size='large', ha='center', va='baseline')

for ax, model in zip(axes[:, 0], data_map.keys()):
    ax.annotate(model_to_name.get(model, 'Unknown model'), xy=(0, 0.5),
                xytext=(-ax.yaxis.labelpad - pad, 0),
                xycoords=ax.yaxis.label, textcoords='offset points',
                size='large', ha='right', va='center')

# plt.legend(loc='upper left')
plt.tight_layout()
plt.savefig('stats_temp.png')
