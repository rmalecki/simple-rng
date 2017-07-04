defmodule SimpleRNG do
  use Bitwise, only_operators: true
  @moduledoc """
  SimpleRNG is a simple random number generator using Marsaglia's MWC (multiply with carry) algorithm.
  """

  @doc """
  Returns random unsigned 64bit integer
  """
  def get_uint({m_w, m_z}) do
    m_z_new = (36969 * (m_z &&& 0xffff) + (m_z >>> 16)) &&& 0xffffffff
    m_w_new = (18000 * (m_w &&& 0xffff) + (m_w >>> 16)) &&& 0xffffffff
    n = ((m_z_new <<< 16) + m_w_new) &&& 0xffffffff
    {{m_w_new, m_z_new}, n}
  end

  @doc """
  Returns integer between min (inclusive) and max (exclusive)
  """
  def get_int(_, min, max) when max <= min, do: min
  def get_int(i, min, max), do: min + rem(i, max - min)

  @doc """
  Returns uniform random sample 0.0 > x < 1.0
  """
  def get_uniform(x), do: (x + 1.0) / (:math.pow(2, 32) + 2)

  @doc """
  Returns normal (Gaussian) random sample with mean 0 and standard deviation 1
  """
  def get_normal(i1, i2) do
    # Box-Muller algorithm
    u1 = get_uniform(i1)
    u2 = get_uniform(i2)
    r = :math.sqrt(-2.0 * :math.log(u1))
    theta = 2.0 * :math.pi * u2
    r * :math.sin(theta)
  end

end

defmodule SimpleRNG.Server do
  use GenServer
  use Bitwise, only_operators: true

  @default_seed {521288629, 362436069}

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(SimpleRNG.Server, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SimpleRNG.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, @default_seed, name: __MODULE__)
  end

  def start(), do: GenServer.start(__MODULE__, @default_seed)

  def stop(pid), do: GenServer.stop(pid)

  @doc """
  Set a new seed for the RNG
  """
  def set_seed(u), do: set_seeds(u >>> 16, u &&& 0xffffffff)

  def set_seeds(m_w, m_z) do
    GenServer.cast __MODULE__, {:set_seed, m_w, m_z}
  end

  def set_seed(pid, u), do: set_seeds(pid, u >>> 16, u &&& 0xffffffff)

  def set_seeds(pid, m_w, m_z) do
    GenServer.cast pid, {:set_seed, m_w, m_z}
  end

  @doc """
  Returns random unsigned 64bit int
  """
  def next do
    GenServer.call __MODULE__, :next
  end

  def next(pid) do
    GenServer.call pid, :next
  end

  # Fisher-Yates (Knuth) shuffle a list
  def shuffle(xs) do
    GenServer.call __MODULE__, {:shuffle, xs}
  end

  def shuffle(xs, pid) do
    GenServer.call pid, {:shuffle, xs}
  end

  ######
  # GenServer implementation

  # Swaps elements a and b in a list
  defp swap(xs, a, b) when a === b, do: xs
  defp swap(xs, a, b) when b < a, do: swap(xs, b, a)
  defp swap(xs, a, b) do
    s1 = Enum.slice(xs, 0, a)
    [x | s2] = Enum.slice(xs, a, b - a)
    [y | s3] = Enum.slice(xs, b, Enum.count(xs))
    s1 ++ [y | s2] ++ [x | s3]
  end

  # Swap element at a with element at random position before a
  defp shuffle(xs, seed, a) when a === 0, do: {seed, xs}
  defp shuffle(xs, seed, a) do
    {new_seed, n} = SimpleRNG.get_uint(seed)
    b = SimpleRNG.get_int(n, 0, a)
    xs |> swap(a - 1, b) |> shuffle(new_seed, a - 1)
  end

  def handle_call(:next, _from, seed) do
    {new_seed, n} = SimpleRNG.get_uint(seed)
    {:reply, n, new_seed}
  end

  def handle_call({:shuffle, xs}, _from, seed) do
    {new_seed, shuffled} = xs |> shuffle(seed, Enum.count(xs))
    {:reply, shuffled, new_seed}
  end

  def handle_cast({:set_seed, m_w, m_z}, _) do
    {:noreply, {m_w &&& 0xffffffff, m_z &&& 0xffffffff}}
  end

end
