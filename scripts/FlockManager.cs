using Godot;

public partial class FlockManager : Node2D
{
	[Export] public PackedScene BoidScene { get; set; }
	[Export] public int InitialCount { get; set; } = 45;
	[Export] public NodePath BirdPath;

	public Vector2? Target { get; set; } = null;

	private Node2D _bird;

	public override void _Ready()
	{
		_bird = GetNodeOrNull<Node2D>(BirdPath);

		GD.Seed((ulong)Time.GetTicksUsec());
		for (int i = 0; i < InitialCount; i++) SpawnBoid();
	}

	public override void _Process(double delta)
	{
		if (_bird != null) Target = _bird.GlobalPosition;
	}

	private void SpawnBoid()
	{
		var b = (Boid)BoidScene.Instantiate();
		AddChild(b);
		b.AddToGroup("boids");

		var size = GetViewportRect().Size;
		b.GlobalPosition = new Vector2(
			(float)GD.RandRange(32, size.X - 32),
			(float)GD.RandRange(32, size.Y - 32)
		);
	}
}
