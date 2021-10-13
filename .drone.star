# Automatically builds docker images and pushes them to the registry.
# Required drone secrets:
#   - docker_repo       eg. 'joellinn/php'
#   - docker_username   user with write permissions to repo
#   - docker_password   password of the user

def main(ctx):
    steps = [
        {
            'name': 'verify',
            'image': 'ubuntu:focal',
            'commands': [
                'DEBIAN_FRONTEND=noninteractive apt-get update',
                'DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl gawk git jq xz-utils',
                './apply-templates.sh',
                '''
                status="$(git status --short)"
                echo "$status"
                [ -z "$status" ]
                ''',
            ]
        },
    ]
    steps.extend(steps_56())
    return [
        {
            'kind': 'pipeline',
            'type': 'docker',
            'name': 'build_push',
            'steps': steps,
            'trigger': {
                'branch': ['master'],
                'event': ['push']
            },
        },
    ]

def steps_56():
    s = []
    for base in ['bullseye', 'buster']:
        for variant in ['apache', 'cli', 'fpm']:
            s.append(step_image('5.6', base, variant))
    return s

def step_image(version, base, variant):
    tag = '{}-{}-{}'.format(version, variant, base)
    path = '{}/{}/{}'.format(version, base, variant)
    return {
        'name': tag,
        'image': 'plugins/docker',
        'settings': {
            'context': path,
            # https://github.com/drone-plugins/drone-docker/issues/335
            'dockerfile': path + '/Dockerfile',
            'tags': [tag],
            'repo': {'from_secret': 'docker_repo'},
            'username': {'from_secret': 'docker_username'},
            'password': {'from_secret': 'docker_password'},
        },
        'depends_on': ['verify'],
    }
