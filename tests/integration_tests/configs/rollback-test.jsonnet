local config = import 'default.jsonnet';

config {
  'highbury_710-1'+: {
    validators: super.validators + [{
      name: 'fullnode',
    }],
  },
}
